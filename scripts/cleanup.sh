#!/bin/sh
# 
# made and verified by scorpii
# -----------------------------------------------------
cat <<"EOF"
  ____ _                  _   _    
 / ___| | ___  __ _ _ __ | | | |_ __  
| |   | |/ _ \/ _` | '_ \| | | | '_ \ 
| |___| |  __/ (_| | | | | |_| | |_) |
 \____|_|\___|\__,_|_| |_|\___/| .__/ 
                               |_|    
EOF
# -----------------------------------------------------
if gum confirm "Start CleanUp right now?" ;then
    echo -e '\033[1;32m'
    echo "System CleanUp started..."
    echo -e '\033[0m'
    yay -Yc
    echo ""
    sudo pacman -Rsn $(pacman -Qqdt) --color always
    echo ""
    sudo paccache -rvu -k 1
    echo ""
    sudo paccache -rv -k 3
    sleep 1
elif [ $? -eq 130 ]; then
        exit 130
else
    exit;
fi
notify-send "CleanUp finished"
