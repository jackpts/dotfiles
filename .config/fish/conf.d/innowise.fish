# SL Project
abbr sl_vpn_on 'sudo wg-quick up /etc/wireguard/clients/slm-yp.conf'
abbr sl_vpn_off 'sudo wg-quick down /etc/wireguard/clients/slm-yp.conf'
abbr sl_be_start 'cd $HOME/bitbucket/SL/sl_back && npm run start:dev'
abbr sl_fe_start 'cd $HOME/bitbucket/SL/sl_frontend && npm run dev'
abbr sl_db_check 'psql -h localhost -p 5432 -U root -d develop -c "\conninfo"'

function sl_db_up --description 'Execute SQL command on SL develop DB using ~/.pgpass'
    if test (count $argv) -lt 1
        echo "Usage: sl_db_up 'SQL_COMMAND'"
        return 1
    end
    PGPASSFILE=$HOME/.pgpass psql -h localhost -p 5432 -U root -d develop -c "$argv[1]"
end
abbr sl_db_up 'sl_db_up'
abbr _sql 'sl_db_up'

function sl_db_restore --description 'Restore SL develop DB from provided dump file'
    set pgpass "$HOME/.pgpass"

    if not test -f $pgpass
        echo "PGPASS file missing: $pgpass" >&2
        return 1
    end

    if test (count $argv) -lt 1
        echo "Usage: sl_db_restore path/to/backup.dmp"
        return 1
    end

    set dump_file $argv[1]
    if not test -f $dump_file
        echo "Dump file not found: $dump_file" >&2
        return 1
    end

    echo "Restoring SL database from $dump_file..."
    if not env PGPASSFILE=$pgpass pg_restore -U root -d develop --no-owner --no-privileges --clean "$dump_file"
        echo "Database restore failed" >&2
        return 1
    end

    echo "Restore completed successfully."
end
abbr sl_db_restore 'sl_db_restore'

function sl_backup --description 'Create SL project archive excluding node_modules and dist while embedding a PG dump'
    set project_dir "$HOME/bitbucket/SL"
    set backup_dir "$HOME/backup"
    set timestamp (date "+%Y%m%d_%H%M%S")
    set archive_name "sl_$timestamp.7z"
    set archive_path "$backup_dir/$archive_name"
    set dump_path "$backup_dir/sl_develop_$timestamp.dump"
    set pgpass "$HOME/.pgpass"
    set current_user (whoami)
    set tmp_dump (sudo -u postgres mktemp --tmpdir sl_develop_dump_XXXXXXXX.dump)

    mkdir -p $backup_dir

    if not test -f $pgpass
        echo "PGPASS file missing: $pgpass" >&2
        return 1
    end

    if test -z "$tmp_dump"
        echo "Failed to prepare temporary dump file" >&2
        return 1
    end

    set dump_cmd "PGPASSFILE=$pgpass pg_dump -h localhost -p 5432 -U postgres -d develop --format=custom --file='$tmp_dump'"
    echo "Dumping SL database to temporary file..."
    if not sudo -u postgres sh -c $dump_cmd
        echo "Postgres dump failed" >&2
        rm -f "$tmp_dump"
        return 1
    end

    sudo mv "$tmp_dump" "$dump_path"
    sudo chown $current_user "$dump_path"

    echo "Creating archive $archive_path with project directory and SQL dump..."
    7z a -xr'!node_modules' -xr'!dist' "$archive_path" "$project_dir/" "$dump_path"
    rm -f "$dump_path"
end
abbr sl_backup 'sl_backup'

abbr sl_be_lint "git diff --name-only --diff-filter=ACMRTUXB origin/master... | grep -E '^(src|apps|libs|test)/.*\\.ts\$' | xargs -r node --max-old-space-size=4096 ./node_modules/.bin/eslint --fix"
abbr sl_fe_lint "npm run format && npm run lint:fix && npm run lint:cycles"

# BitBucket check via SSH
abbr bb_test 'ssh -T git@bitbucket.org'

# Google Chat Bot Project
abbr gcb_tun_up 'cd $HOME/gitlab/googlechatbot && lt --port 3000'
abbr gcb_url 'lt --port 3000'
abbr gcb_start 'cd $HOME/gitlab/googlechatbot && pnpm start'

function gcb_backup --description 'Archive Google Chat Bot project excluding node_modules and dist'
    set project_dir "$HOME/gitlab/googlechatbot"
    set backup_dir "$HOME/backup"
    set timestamp (date "+%Y%m%d_%H%M%S")
    set archive_name "gcb_$timestamp.7z"
    set archive_path "$backup_dir/$archive_name"

    mkdir -p $backup_dir
    echo "Archiving Google Chat Bot project directory $project_dir..."
    7z a -xr'!node_modules' -xr'!dist' "$archive_path" "$project_dir/"
end
abbr gcb_backup 'gcb_backup'
