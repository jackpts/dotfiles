# SL Project
abbr sl_vpn_on 'sudo wg-quick up /etc/wireguard/clients/slm-yp.conf'
abbr sl_vpn_off 'sudo wg-quick down /etc/wireguard/clients/slm-yp.conf'
abbr sl_be_start 'cd $HOME/bitbucket/SL/sl_back && npm run start:dev'
abbr sl_fe_start 'cd $HOME/bitbucket/SL/sl_frontend && npm run dev'
abbr sl_db_check 'psql -h localhost -p 5432 -U root -d develop -c "\conninfo"'

function sl_backup --description 'Create SL project archive excluding node_modules and *.dump files'
    set project_dir "$HOME/bitbucket/SL"
    set backup_dir "$HOME/backup"
    set timestamp (date "+%Y%m%d_%H%M%S")
    set archive_name "sl_$timestamp.7z"
    set archive_path "$backup_dir/$archive_name"

    mkdir -p $backup_dir
    7z a -xr'!node_modules' -xr'!*.dump' -xr'!dist' "$archive_path" "$project_dir/"
end
abbr sl_backup 'sl_backup'

# BitBucket check via SSH
abbr bb_test 'ssh -T git@bitbucket.org'

# Google Chat Bot Project
abbr gcb_tun_up 'cd $HOME/gitlab/googlechatbot && lt --port 3000'
abbr gcb_url 'lt --port 3000'
abbr gcb_start 'cd $HOME/gitlab/googlechatbot && npm run dev'