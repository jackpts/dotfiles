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
  command -v yay >/dev/null 2>&1 && helper=yay || helper=paru
fi

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
