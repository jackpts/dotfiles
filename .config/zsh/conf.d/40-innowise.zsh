alias sl_vpn_on='sudo wg-quick up /etc/wireguard/clients/slm-yp.conf'
alias sl_vpn_off='sudo wg-quick down /etc/wireguard/clients/slm-yp.conf'
alias sl_be_start='cd $HOME/bitbucket/SL/sl_back && npm run start:dev'
alias sl_fe_start='cd $HOME/bitbucket/SL/sl_frontend && npm run dev'
alias sl_db_check='psql -h localhost -p 5432 -U root -d develop -c "\\conninfo"'

sl_db_up() {
  if [[ "$#" -lt 1 ]]; then
    echo "Usage: sl_db_up 'SQL_COMMAND'"
    return 1
  fi
  PGPASSFILE="$HOME/.pgpass" psql -h localhost -p 5432 -U root -d develop -c "$1"
}

alias sl_db_up='sl_db_up'
alias _sql='sl_db_up'

sl_db_restore() {
  local pgpass="$HOME/.pgpass"
  [[ -f "$pgpass" ]] || { echo "PGPASS file missing: $pgpass" >&2; return 1; }
  [[ "$#" -ge 1 ]] || { echo "Usage: sl_db_restore path/to/backup.dmp"; return 1; }
  local dump_file="$1"
  [[ -f "$dump_file" ]] || { echo "Dump file not found: $dump_file" >&2; return 1; }

  echo "Restoring SL database from $dump_file..."
  env PGPASSFILE="$pgpass" pg_restore -U root -d develop --no-owner --no-privileges --clean "$dump_file" || {
    echo "Database restore failed" >&2
    return 1
  }

  echo "Restore completed successfully."
}

alias sl_db_restore='sl_db_restore'

sl_backup() {
  local project_dir="$HOME/bitbucket/SL"
  local backup_dir="$HOME/backup"
  local timestamp
  timestamp="$(date +"%Y%m%d_%H%M%S")"
  local archive_name="sl_${timestamp}.7z"
  local archive_path="$backup_dir/$archive_name"
  local dump_path="$backup_dir/sl_develop_${timestamp}.dump"
  local pgpass="$HOME/.pgpass"
  local current_user
  current_user="$(whoami)"
  local tmp_dump
  tmp_dump="$(sudo -u postgres mktemp --tmpdir sl_develop_dump_XXXXXXXX.dump)"

  mkdir -p "$backup_dir"

  [[ -f "$pgpass" ]] || { echo "PGPASS file missing: $pgpass" >&2; return 1; }
  [[ -n "$tmp_dump" ]] || { echo "Failed to prepare temporary dump file" >&2; return 1; }

  local dump_cmd
  dump_cmd="PGPASSFILE=$pgpass pg_dump -h localhost -p 5432 -U postgres -d develop --format=custom --file='$tmp_dump'"

  echo "Dumping SL database to temporary file..."
  sudo -u postgres sh -c "$dump_cmd" || {
    echo "Postgres dump failed" >&2
    rm -f "$tmp_dump"
    return 1
  }

  sudo mv "$tmp_dump" "$dump_path"
  sudo chown "$current_user" "$dump_path"

  echo "Creating archive $archive_path with project directory and SQL dump..."
  7z a -xr'!node_modules' -xr'!dist' "$archive_path" "$project_dir/" "$dump_path"
  rm -f "$dump_path"
}

alias sl_backup='sl_backup'

alias sl_be_lint="git diff --name-only --diff-filter=ACMRTUXB origin/master... | grep -E '^(src|apps|libs|test)/.*\\.ts$' | xargs -r node --max-old-space-size=4096 ./node_modules/.bin/eslint --fix"

alias bb_test='ssh -T git@bitbucket.org'

alias gcb_tun_up='cd $HOME/gitlab/googlechatbot && lt --port 3000'
alias gcb_url='lt --port 3000'
alias gcb_start='cd $HOME/gitlab/googlechatbot && pnpm start'

gcb_backup() {
  local project_dir="$HOME/gitlab/googlechatbot"
  local backup_dir="$HOME/backup"
  local timestamp
  timestamp="$(date +"%Y%m%d_%H%M%S")"
  local archive_name="gcb_${timestamp}.7z"
  local archive_path="$backup_dir/$archive_name"

  mkdir -p "$backup_dir"
  echo "Archiving Google Chat Bot project directory $project_dir..."
  7z a -xr'!node_modules' -xr'!dist' "$archive_path" "$project_dir/"
}

alias gcb_backup='gcb_backup'
