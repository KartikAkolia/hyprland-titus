#!/bin/bash

# Define variables
GREEN="$(tput setaf 2)[OK]$(tput sgr0)"
RED="$(tput setaf 1)[ERROR]$(tput sgr0)"
YELLOW="$(tput setaf 3)[NOTE]$(tput sgr0)"
CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"
LOG="install.log"

# Set the script to exit on error
set -e

# Welcome message
printf "$(tput setaf 2) Welcome to the Arch Linux YAY Hyprland installer!\n $(tput sgr0)"
sleep 2

# Warning message
printf "$YELLOW PLEASE BACKUP YOUR FILES BEFORE PROCEEDING! This script will overwrite some of your configs and files!\n"
sleep 2

# Password warning message
printf "\n$YELLOW Some commands require you to enter your password. If you are worried about entering your password, you can cancel the script now with CTRL Q or CTRL C and review the contents of this script.\n"
sleep 3

# Function to print error messages
print_error() {
    printf " %s%s\n" "$RED" "$1" >&2
}

# Function to print success messages
print_success() {
    printf "%s%s\n" "$GREEN" "$1"
}

# Check if yay is installed
if ! command -v yay &> /dev/null; then
    printf "\n%s - yay was NOT located\n" "$YELLOW"
    read -n1 -rep "${CAT} Would you like to install yay (y,n)? " INST
    if [[ $INST =~ ^[Yy]$ ]]; then
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm 2>&1 | tee -a $LOG
        cd ..
    else
        print_error "yay is required for this script, now exiting"
        exit 1
    fi
fi

# Update system before proceeding
printf "${YELLOW} System Update to avoid issues\n"
yay -Syu --noconfirm 2>&1 | tee -a $LOG

# Install packages
read -n1 -rep "${CAT} Would you like to install the packages? (y/n)? " inst
echo

if [[ $inst =~ ^[Yy]$ ]]; then
    git_pkgs="grimblast-git sddm-git hyprpicker-git waybar-hyprland-git"
    hypr_pkgs="hyprland wl-clipboard wf-recorder rofi wlogout swaylock-effects dunst swaybg kitty"
    font_pkgs="ttf-nerd-fonts-symbols-common otf-firamono-nerd inter-font otf-sora ttf-fantasque-nerd noto-fonts noto-fonts-emoji ttf-comfortaa"
    font_pkgs2="ttf-jetbrains-mono-nerd ttf-icomoon-feather ttf-iosevka-nerd adobe-source-code-pro-fonts"
    app_pkgs="nwg-look-bin qt5ct btop jq gvfs ffmpegthumbs swww mousepad mpv playerctl pamixer noise-suppression-for-voice"
    app_pkgs2="polkit-gnome ffmpeg neovim viewnior pavucontrol thunar ffmpegthumbnailer tumbler thunar-archive-plugin xdg-user-dirs"
    theme_pkgs="nordic-theme papirus-icon-theme starship"

    yay -R --noconfirm swaylock waybar

    if ! yay -S --noconfirm $git_pkgs $hypr_pkgs $font_pkgs $font_pkgs2 $app_pkgs $app_pkgs2 $theme_pkgs 2>&1 | tee -a $LOG; then
        print_error "Failed to install additional packages - please check the install.log"
        exit 1
    fi
    xdg-user-dirs-update
    print_success "All necessary packages installed successfully."
else
    print_error "No packages installed. Exiting..."
    exit 1
fi

# Copy Config Files
read -n1 -rep "${CAT} Would you like to copy config files? (y,n)? " CFG
if [[ $CFG =~ ^[Yy]$ ]]; then
    printf "Copying config files...\n"
    cp -r dotconfig/dunst ~/.config/ 2>&1 | tee -a $LOG
    cp -r dotconfig/hypr ~/.config/ 2>&1 | tee -a $LOG
    cp -r dotconfig/kitty ~/.config/ 2>&1 | tee -a $LOG
    cp -r dotconfig/pipewire ~/.config/ 2>&1 | tee -a $LOG
    cp -r dotconfig/rofi ~/.config/ 2>&1 | tee -a $LOG
    cp -r dotconfig/swaylock ~/.config/ 2>&1 | tee -a $LOG
    cp -r dotconfig/waybar ~/.config/ 2>&1 | tee -a $LOG
    cp -r dotconfig/wlogout ~/.config/ 2>&1 | tee -a $LOG

    # Set some files as executable 
    chmod +x ~/.config/hypr/xdg-portal-hyprland
    chmod +x ~/.config/waybar/scripts/waybar-wttr.py
fi

# Add Fonts for Waybar
mkdir -p "$HOME/Downloads/nerdfonts/"
cd "$HOME/Downloads/"
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/CascadiaCode.zip
unzip '*.zip' -d "$HOME/Downloads/nerdfonts/"
rm -rf *.zip
sudo cp -R "$HOME/Downloads/nerdfonts/" /usr/share/fonts/
fc-cache -rv

# Enable SDDM Autologin
read -n1 -rep 'Would you like to enable SDDM autologin? (y,n)? ' SDDM
if [[ $SDDM =~ ^[Yy]$ ]]; then
    LOC="/etc/sddm.conf"
    echo -e "The following has been added to $LOC.\n"
    echo -e "[Autologin]\nUser=$(whoami)\nSession=hyprland" | sudo tee -a $LOC
    echo -e "\nEnabling SDDM service...\n"
    sudo systemctl enable sddm
    sleep 3
fi

# Install Bluetooth Packages
read -n1 -rep "${CAT} OPTIONAL - Would you like to install Bluetooth packages? (y,n)? " BLUETOOTH
if [[ $BLUETOOTH =~ ^[Yy]$ ]]; then
    printf "Installing Bluetooth Packages...\n"
    blue_pkgs="bluez bluez-utils blueman"
    if ! yay -S --noconfirm $blue_pkgs 2>&1 | tee -a $LOG; then
        print_error "Failed to install Bluetooth packages - please check the install.log"
    else
        printf "Activating Bluetooth Services...\n"
        sudo systemctl enable --now bluetooth.service
        sleep 2
    fi
else
    printf "${YELLOW} No Bluetooth packages installed.\n"
fi

# Script is done
printf "\n${GREEN} Installation Completed.\n"
echo -e "${GREEN} You can start Hyprland by typing Hyprland (note the capital H).\n"
read -n1 -rep "${CAT} Would you like to start Hyprland now? (y,n)? " HYP
if [[ $HYP =~ ^[Yy]$ ]]; then
    if command -v Hyprland &> /dev/null; then
        exec Hyprland
    else
        print_error "Hyprland not found. Please make sure Hyprland is installed by checking install.log."
        exit 1
    fi
else
    exit 0
fi
