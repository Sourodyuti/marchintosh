========================================
AUR PACKAGES FROM YOUR ORIGINAL SYSTEM
========================================

After installation, run this as your regular user (NOT root):

    /root/install_aur_packages.sh

Or install manually:
    - brave-bin
    - spotify  
    - visual-studio-code-bin
    - yay (AUR helper)

To install manually:
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si
    yay -S brave-bin spotify visual-studio-code-bin
