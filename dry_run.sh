#!/bin/bash

# This is also made for the Surface Pro 7+, though running the script might also
# work on your computer. Good luck, and enjoy

# Set dry run mode
dry_run=true

if [ "$UID" -ne 0 ]; then
    echo "This script must be run as root"
    exit 1
else
    # clone the repositories
    git clone https://github.com/quo/ithc
    git clone https://github.com/linux-surface/iptsd

    # add the Linux Surface repository
    if [ "$dry_run" != true ]; then
        echo "deb [trusted=yes] https://pkg.surfacelinux.com/debian stable main" | sudo tee /etc/apt/sources.list.d/linux-surface.list
        sudo apt update
    fi

    # install dkms and meson
    if [ "$dry_run" != true ]; then
        sudo apt install dkms meson build-essential -y
    fi

    # cd into ithc-linux and run make dkms-install
    cd ~/ithc/ithc-linux
    if [ "$dry_run" != true ]; then
        sudo make dkms-install
    fi

    # add ithc to modprobe
    if [ "$dry_run" != true ]; then
        echo "ithc" | sudo tee -a /etc/modules-load.d/ithc.conf
    fi

    # install kernel needed
    if [ "$dry_run" != true ]; then
        sudo apt install linux-surface-headers linux-image-surface libwacom-surface -y
    fi

    # adding secure boot
    if [ "$dry_run" != true ]; then
        sudo apt install surface-secureboot
    fi

    # cd into iptsd and run meson build, then ninja -C build
    cd ~/iptsd
    if [ "$dry_run" != true ]; then
        meson build
        ninja -C build
    fi

    # find hidraw device
    hidrawN=$(sudo ./etc/iptsd-find-hidraw)

    # create daemon script
    mkdir ~/.daemonscript
    if [ "$dry_run" != true ]; then
        echo "sudo ./build/src/daemon/iptsd $hidrawN" > ~/.daemonscript/iptsdscript.sh
    fi

    # edit grub config
    if [ "$dry_run" != true ]; then
        sudo sed -i "s/GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX=\"rhgb intremap=nosid '~\/.daemonscript\/iptsdscript.sh' quiet\"/g" /etc/default/grub
        sudo update-grub
    fi
fi
