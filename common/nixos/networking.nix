# SPDX-FileCopyrightText: 2024 Dom Rodriguez <shymega@shymega.org.uk
#
# SPDX-License-Identifier: GPL-3.0-only
#
{
  libx,
  self,
  config,
  pkgs,
  inputs,
  ...
}: let
  inherit (libx) isNixOS;
  inherit (pkgs.lib) optionals hasSuffix;
in {
  networking.networkmanager = {
    dns = "systemd-resolved";
    unmanaged = [
      "iphone0"
      "android0"
    ];
    ensureProfiles.profiles =
      inputs.nixfigs-networks.networks.all
      // inputs.nixfigs-networks.networks.work;
    wifi.macAddress = "stable-ssid";
    wifi.scanRandMacAddress = true;
    ethernet.macAddress = "stable";
    wifi.powersave = true;
    enable = true;
    dispatcherScripts = optionals (isNixOS && hasSuffix "-LINUX" config.networking.hostName) [
      {
        source = "${self}/static/nixos/rootfs/etc/NetworkManager/dispatcher.d/05-wireless-toggle";
        type = "basic";
      }
      {
        source = "${self}/static/nixos/rootfs/etc/NetworkManager/dispatcher.d/10-net-targets";
        type = "basic";
      }
    ];
  };

  networking.extraHosts = ''
    192.168.8.1 gl-inet.routers.rnet.rodriguez.org.uk
    172.28.13.63 mail.delta-zero.rodriguez.org.uk taskd.shymega.org.uk
  '';

  programs.nm-applet = {
    enable = true;
    indicator = true;
  };
}
