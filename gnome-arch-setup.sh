#!/bin/bash
set -e


# Funktion zum Anzeigen von Text in roter Farbe
print_red() {
    echo -e "\e[91m$1\e[0m"
}

update_and_install_packages() {
    echo "Updating and installing additional packages"
    sudo pacman -Syu git mtpfs ntfs-3g deja-dup power-profiles-daemon bluez bluez-utils gnome-firmware rustup npm cantarell-fonts rclone libreoffice-fresh
}

setup_aur_helper() {
    echo "Setting up AUR helper"
    git clone https://aur.archlinux.org/paru.git && cd paru && makepkg -si --noconfirm && cd .. && rm -rf ./paru
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

setup_npm() {
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
    code
    sleep 5s
    echo "Changing some VS-Code Settings"
    echo '{
        "window.dialogStyle": "custom",
        "window.titleBarStyle": "custom",
        "editor.cursorSmoothCaretAnimation": "on"
    }' > ~/.config/Code/User/settings.json
    xdg-mime default org.gnome.Nautilus.desktop inode/directory
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

debloat() {
    sudo pacman -Rcns gnome-maps gnome-music gnome-weather gnome-remote-desktop 
}

bootsplash() {
    paru -S plymouth
    sudo sed -i 's/udev/udev plymouth/g' /etc/mkinitcpio.conf
    sudo mkinitcpio -p linux-hardened
    sudo sed -i 's/rw/rw quiet splash/g' /boot/loader/entries/*linux-hardened.conf
    sudo systemctl disable gdm
    sudo systemctl enable gdm
    git clone https://github.com/murkl/plymouth-theme-arch-os.git 
    cd plymouth-theme-arch-os
    sudo cp -r ./src /usr/share/plymouth/themes/arch-os
    sudo plymouth-set-default-theme -R arch-os
    cd ..
}

run_script() {
    update_and_install_packages
    setup_rust
    setup_aur_helper
    debloat
    generate_ssh_key
    enable_bluetooth
    install_browser_and_packages
    setup_npm
    setup_gnome_environment
    change_vscode_settings
    enable_unprivileged_userns_clone
    other_stuff
    configure_git
    proton_drive_setup
    proton_vpn
    bootsplash
}

proton_drive_setup() {
    print_red "Do you want to add Proton Drive as mount? (y/N): "
    read response
    if [ "$response" == "y" ]; then
        print_red "To auto mount Proton Drive you have to name the remote 'Proton' not 'Proton Drive'"
        print_red "Instructions: https://rclone.org/protondrive/"
        print_red "New Remote -> !'Proton'! -> 'protondrive' -> your username -> your password -> your 2FA -> add Mailbox Password into 'advanced options' -> ENTER until 'Yes this is OK' -> Yes this is OK"
        rclone config
        cp ./rclone-autostart ~/.config/systemd/user/rclone@Proton.service
        mkdir ~/Proton
        systemctl --user enable rclone@Proton
    else
        echo "Skipped Proton Drive"
    fi
}

proton_vpn() {
    print_red "Do you want to install Proton VPN? (y/N): "
    read response
    if [ "$response" == "y" ]; then
        paru -S proton-vpn-gtk-app network-manager-applet
    else
        echo "Skipped Proton VPN"
    fi
}

echo  "This script will reboot your device at the end"
# Benutzerabfrage
print_red "Do you really want to continue? (y/N): "
read response

# Überprüfen der Benutzerantwort
if [ "$response" == "y" ]; then
    run_script
    reboot
else
    echo "Aborted."
fi
