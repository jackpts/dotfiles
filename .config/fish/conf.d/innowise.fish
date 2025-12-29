# SL Project
abbr sl_vpn_on 'sudo wg-quick up /etc/wireguard/clients/slm-yp.conf'
abbr sl_vpn_off 'sudo wg-quick down /etc/wireguard/clients/slm-yp.conf'
abbr sl_be_start 'cd $HOME/bitbucket/SL/sl_back && npm run start:dev'
abbr sl_fe_start 'cd $HOME/bitbucket/SL/sl_frontend && npm run dev'
abbr sl_db_check 'psql -h localhost -p 5432 -U root -d develop -c "\conninfo"'

# BitBucket check via SSH
abbr bb_test 'ssh -T git@bitbucket.org'

# Google Chat Bot Project
abbr gcb_tun_up 'cd $HOME/gitlab/googlechatbot && lt --port 3000'
abbr gcb_url 'lt --port 3000'
abbr gcb_start 'cd $HOME/gitlab/googlechatbot && npm run dev'