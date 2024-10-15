# SPDX-FileCopyrightText: 2024 Dom Rodriguez <shymega@shymega.org.uk
#
# SPDX-License-Identifier: GPL-3.0-only

#

{ inputs, ... }:
{
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  environment.persistence."/persist" = {
    directories = [
      "/etc/NetworkManager/system-connections"
      "/etc/secureboot"
      "/opt"
      "/root"
      "/usr/local"
    ]; # ++ lib.optionals (config.networking.hostName == "NEO-LINUX" || config.networking.hostName == "MORPHEUS-LINUX" || config.networking.hostName == "TWINS-LINUX")
    #        [
    #          "/var/lib/NetworkManager"
    #          "/var/lib/bluetooth"
    #          "/var/lib/cni"
    #          "/var/lib/containers"
    #          "/var/lib/docker"
    #          "/var/lib/flatpak"
    #          "/var/lib/libvirt"
    #          "/var/lib/lxc"
    #          "/var/lib/lxd"
    #          "/var/lib/machines"
    #          "/var/lib/nixos"
    #          "/var/lib/postfix"
    #          "/var/spool/atjobs"
    #          "/var/spool/atspool"
    #          "/var/spool/leafnode"
    #      ];
  };

  security.sudo.extraConfig = ''
    Defaults lecture = never
  '';
}
