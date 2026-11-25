#!/usr/bin/env bash

# Full system upgrade: official repos + AUR.
#
# Uses the normal AUR helper when aur.archlinux.org is reachable.
# Falls back to official repos (pacman) plus AUR builds fetched from the
# official GitHub mirror (github.com/archlinux/aur) when the AUR is
# unreachable (e.g. during the ongoing DDoS outages).

set -u
export LC_ALL=C

AUR_RPC="https://aur.archlinux.org/rpc?v=5&type=info&arg[]=yay"
MIRROR_RAW="https://raw.githubusercontent.com/archlinux/aur"
MIRROR_GIT="https://github.com/archlinux/aur.git"
WORK="${XDG_CACHE_HOME:-$HOME/.cache}/aur-mirror-update"
mkdir -p "$WORK"

helper="${aurhelper:-}"
if [ -z "$helper" ]; then
  # Prefer paru (the AUR helper used on this setup); fall back to yay.
  command -v paru >/dev/null 2>&1 && helper=paru || helper=yay
fi

# An interrupted build can leave a stale, non-empty directory at the helper's
# clone target (e.g. a lone pkg/ dir with no .git/PKGBUILD). git then refuses to
# clone and aborts the whole upgrade. Purge such entries from both AUR caches
# before starting, so re-cloning succeeds and switching helpers is safe.
clean_stale_clones() {
  local cache="$1" dir
  [ -d "$cache" ] || return 0
  for dir in "$cache"/*; do
    [ -d "$dir" ] || continue
    if [ ! -d "$dir/.git" ] && [ ! -f "$dir/PKGBUILD" ]; then
      echo "==> Removing stale AUR cache entry: $dir" >&2
      chmod -R u+rwX "$dir" 2>/dev/null || true
      rm -rf "$dir"
    fi
  done
}

cache_root="${XDG_CACHE_HOME:-$HOME/.cache}"
clean_stale_clones "$cache_root/yay"
clean_stale_clones "$cache_root/paru/clone"

reachable() {
  curl -fsS --max-time 8 -o /dev/null "$1" 2>/dev/null
}

if reachable "$AUR_RPC"; then
  exec "$helper" -Suyy --noconfirm
fi

echo "==> aur.archlinux.org unreachable (AUR outage?)" >&2
echo "    Updating official repos via pacman and AUR from the GitHub mirror." >&2

sudo pacman -Syyu --noconfirm || true

echo "==> Updating AUR packages from $MIRROR_GIT" >&2

declare -A base_of=() ver_of=()
for pkg in $(pacman -Qmq 2>/dev/null); do
  ver_of["$pkg"]=$(pacman -Q "$pkg" 2>/dev/null | awk '{print $2}')
done
for desc in /var/lib/pacman/local/*/desc; do
  name=$(awk '/^%NAME%$/{getline; print; exit}' "$desc")
  [ -n "${base_of[$name]:-}" ] && continue
  base_of["$name"]=$(awk '/^%BASE%$/{getline; print; exit}' "$desc")
done

updated=0
skipped=0
failures=0
fail_list=()
bases=$(for name in "${!base_of[@]}"; do [ -n "${ver_of[$name]:-}" ] && echo "${base_of[$name]}"; done | sort -u)

for base in $bases; do
  curver=""
  for name in "${!base_of[@]}"; do
    if [ "${base_of[$name]}" = "$base" ] && [ -n "${ver_of[$name]:-}" ]; then
      curver="${ver_of[$name]}"
      break
    fi
  done
  [ -z "$curver" ] && { skipped=$((skipped + 1)); continue; }

  srcinfo=$(curl -fsS --max-time 10 "$MIRROR_RAW/$base/.SRCINFO" 2>/dev/null) || {
    skipped=$((skipped + 1)); continue
  }
  epoch=$(printf '%s\n' "$srcinfo" | awk '/^[[:space:]]*epoch =/{print $3; exit}')
  pkgver=$(printf '%s\n' "$srcinfo" | awk '/^[[:space:]]*pkgver =/{print $3; exit}')
  pkgrel=$(printf '%s\n' "$srcinfo" | awk '/^[[:space:]]*pkgrel =/{print $3; exit}')
  newver="${epoch:+$epoch:}$pkgver-$pkgrel"

  if [ "$(vercmp "$newver" "$curver")" -le 0 ]; then
    skipped=$((skipped + 1)); continue
  fi

  echo "==> $base: $curver -> $newver" >&2
  dir="$WORK/$base"
  rm -rf "$dir"
  if ! timeout 120 git clone --depth 1 --branch "$base" --single-branch "$MIRROR_GIT" "$dir" 2>/dev/null; then
    failures=$((failures + 1)); fail_list+=("$base"); continue
  fi

  if (cd "$dir" && makepkg -si --noconfirm --needed); then
    updated=$((updated + 1))
  else
    failures=$((failures + 1)); fail_list+=("$base")
  fi
done

echo "==> AUR mirror update done: $updated updated, $skipped up-to-date/skipped, $failures failed" >&2
if [ ${#fail_list[@]} -gt 0 ]; then
  printf '    failed: %s\n' "${fail_list[*]}" >&2
fi
