# SPDX-FileCopyrightText: 2024 Dom Rodriguez <shymega@shymega.org.uk
#
# SPDX-License-Identifier: GPL-3.0-only
#
{
  lib,
  hostname,
  config,
  ...
}: let
  isPersonal =
    hostname
    == "NEO-LINUX"
    || hostname == "MORPHEUS-LINUX"
    || hostname == "TRINITY-LINUX"
    || hostname == "TWINS-LINUX"
    || hostname == "DEUSEX-LINUX"
    || hostname == "THOR-LINUX";
  isDeltaZero =
    hostname
    == "DELTA-ZERO"
    || hostname == "delta-zero";
in {
  imports =
    [
      ./appimage.nix
      ./bluetooth.nix
      ./fido2.nix
      ./firmware.nix
      ./inst_packages.nix
      ./kernel_params.nix
      ./keychron.nix
      ./networking.nix
      ./systemd-initrd.nix
      ./utils
    ]
    ++ (
      if isPersonal
      then [
        ./automount.nix
        ./custom-systemd-units
        ./davmail.nix
        ./dovecot2.nix
        ./graphical.nix
        ./impermanence.nix
        ./matrix.nix
        ./postfix.nix
        ./steam-hardware.nix
        ./xdg.nix
      ]
      else []
    )
    ++ (
      if isDeltaZero
      then [
        ./davmail.nix
        ./dovecot2.nix
        ./postfix.nix
      ]
      else []
    );

  boot.kernelParams = ["log_buf_len=10M"];

  documentation = {
    dev.enable = true;
    man.generateCaches = true;
  };

  i18n.defaultLocale = "en_GB.UTF-8";

  networking = {
    firewall = {
      trustedInterfaces = ["tailscale0"];
      allowedUDPPorts = [config.services.tailscale.port];
    };
  };

  programs = {
    command-not-found.enable = false;
    mosh.enable = true;
    zsh.enableGlobalCompInit = false;
  };

  security = {
    sudo = {
      enable = true;
      wheelNeedsPassword = lib.mkDefault false;
    };
  };

  services = {
    dbus.implementation = "broker";
    openssh = {
      enable = true;
      settings.PermitRootLogin = lib.mkDefault "no";
    };
    tailscale.enable = true;
  };

  systemd = {
    services.tailscaled = {
      after = ["network-online.target"];
      wants = ["network-online.target"];
    };
  };

  services.udev.extraRules = ''
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="5548", ATTRS{idProduct}=="6670", GROUP="users", TAG+="uaccess"
  '';

  users.mutableUsers = false;
  services.atd.enable = true;
  programs.nix-ld.enable = true;
  programs.java.binfmt = true;
  services.incron.enable = true;
  security.pam.services = let
    inherit (lib) optionalAttrs hasSuffix;
  in
    optionalAttrs (hasSuffix "-LINUX" hostname) {
      login.gnupg = {
        enable = true;
        noAutostart = true;
        storeOnly = true;
      };
      greetd.gnupg = {
        enable = true;
        noAutostart = true;
        storeOnly = true;
      };
    };
}
