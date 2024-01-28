#!/bin/bash

# Funktion zum Anzeigen von Text in roter Farbe
print_red() {
    echo -e "\e[91m$1\e[0m"
}

update_and_install_packages() {
    echo "Updating and installing additional packages"
    sudo pacman -Syu git mtpfs ntfs-3g deja-dup power-profiles-daemon bluez bluez-utils gnome-firmware rustup npm
}

setup_aur_helper() {
    echo "Setting up AUR helper"
    git clone https://aur.archlinux.org/paru.git && cd paru && makepkg -si --noconfirm && cd .. && rm -r ./paru
    sudo chmod o+w /etc/paru.conf
    echo -e "\n#Skip PGKBUILD Check \nSkipReview" >> /etc/paru.conf    
    sudo chmod o-w /etc/paru.conf
}

generate_ssh_key() {
    echo "Generating SSH-Key"
    ssh-keygen -f ~/.ssh/id_rsa -O no-touch-required -b 16384
}

setup_rust() {
    echo "Starting setup for rust"
    rustup default stable
}

enable_bluetooth() {
    echo "Enabling bluetooth"
    sudo systemctl enable bluetooth
}

install_browser_and_packages() {
    echo "Installing browser and additional packages"
    paru -Syu visual-studio-code-bin ungoogled-chromium-bin discord_arch_electron
}

secure_npm() {
    echo "Securing NPM"
    mkdir -p ~/.npm-global
    echo -e "export NPM_CONFIG_PREFIX=~/.npm-global\nexport PATH=\$PATH:~/.npm-global/bin" >> ~/.bashrc
}

setup_gnome_environment() {
    echo "Setting up Gnome Environment"
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
    gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
}

change_vscode_settings() {
    echo "Changing some VS-Code Settings"
    echo '{
        "window.dialogStyle": "custom",
        "window.titleBarStyle": "custom",
        "editor.cursorSmoothCaretAnimation": "on"
    }' > ~/.config/Code/User/settings.json
}

enable_unprivileged_userns_clone() {
    echo "Enabling unprivileged userns clone (fixing some applications in Hardened Kernel)"
    echo 'kernel.unprivileged_userns_clone=1' | sudo tee -a /etc/sysctl.d/99-unprivileged-userns.conf
    sudo sysctl --system
}

other_stuff() {
    echo "Other stuff"
    timedatectl set-timezone Europe/Berlin
}

configure_git() {
    echo "Configuring Git"
    read -p "Enter your git name: " git_name
    read -p "Enter your email: " email

    git config --global user.name "$git_name"
    git config --global user.email "$email"
}

install_office() {
    paru -Sy onlyoffice-bin
}

debloat() {
    sudo pacman -Rcns gnome-maps gnome-music gnome-weather gnome-remote-desktop 
}

run_script() {
    update_and_install_packages
    setup_aur_helper
    debloat
    generate_ssh_key
    setup_rust
    enable_bluetooth
    install_browser_and_packages
    secure_npm
    setup_gnome_environment
    change_vscode_settings
    enable_unprivileged_userns_clone
    other_stuff
    configure_git
}

# Benutzerabfrage
print_red "Do you really want to continue? (yes/no): "
read response

# Überprüfen der Benutzerantwort
if [ "$response" == "yes" ]; then
    echo "Continuing..."
    run_script
else
    echo "Aborted."
fi
