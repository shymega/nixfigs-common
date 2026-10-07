# SPDX-FileCopyrightText: 2023-2026 Dom 'shymega' Rodriguez <shymega@shymega.org.uk>
#
# SPDX-License-Identifier: Apache-2.0
#
{pkgs, inputs, ...}: {
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
    inputs.flox.packages.${pkgs.stdenv.hostPlatform.system}.default
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
