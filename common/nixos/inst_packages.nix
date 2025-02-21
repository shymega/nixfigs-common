# SPDX-FileCopyrightText: 2024 Dom Rodriguez <shymega@shymega.org.uk
#
# SPDX-License-Identifier: GPL-3.0-only
#
{pkgs, ...}: {
  environment.systemPackages = with pkgs.unstable; [
    acpi
    aria2
    curl
    ddcutil
    encfs
    fido2luks
    fuse
    git
    gnupg
    goimapnotify-patched
    htop
    ifuse
    iw
    libimobiledevice
    lm_sensors
    nano
    nvme-cli
    pciutils
    powertop
    smartmontools
    solo2-cli
    syncthing
    tmux
    usbutils
    wget
  ];
}
