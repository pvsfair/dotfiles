#!/bin/bash
# Path to your manually downloaded .deb packages
DEB_DIR="$HOME/deb-updates"
INSTALLED_TAG="installed-"
CONFIRM=false
[[ "$1" == "--confirm" ]] && CONFIRM=true
COLS=$(tput cols 2>/dev/null || echo 40)
LINE=$(printf '═%.0s' $(seq 1 "$COLS"))

# Check for .deb files that haven't been installed yet
if find "$DEB_DIR" -maxdepth 1 -name "*.deb" ! -name "${INSTALLED_TAG}*" | grep -q .; then
    for deb in "$DEB_DIR"/*.deb; do
        [[ "$(basename "$deb")" == ${INSTALLED_TAG}* ]] && continue
        if $CONFIRM; then
            read -p "Install $(basename "$deb")? [y/N] " ans
            [[ "$ans" != [yY] ]] && continue
        fi
        echo -e "\n$LINE"
        echo "  📦 Installing: $(basename "$deb")"
        echo "$LINE"
        sudo dpkg -i "$deb" && mv "$deb" "$DEB_DIR/${INSTALLED_TAG}$(basename "$deb")" && echo -e "$LINE\n  ✅ $(basename "$deb") installed successfully\n$LINE\n"
    done
    echo -e "\n$LINE"
    echo "  🔧 Fixing missing dependencies..."
    echo "$LINE"
    sudo apt-get install -f -y
    echo -e "$LINE\n  ✅ Dependencies resolved\n$LINE\n"
else
    echo -e "\n$LINE"
    echo "  ℹ️  No new .deb packages found in $DEB_DIR"
    echo -e "$LINE\n"
fi
