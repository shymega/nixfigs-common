# SPDX-FileCopyrightText: 2023-2026 Dom 'shymega' Rodriguez <shymega@shymega.org.uk>
#
# SPDX-License-Identifier: Apache-2.0
#
{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    acpi
    aria2
    curl
    dovecot_pigeonhole
    fido2luks
    fuse
    git
    gnupg
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
    syncthing
    tmux
    usbutils
    wget
    xdg-utils
  ];
}
