# SPDX-FileCopyrightText: 2024 Dom Rodriguez <shymega@shymega.org.uk
#
# SPDX-License-Identifier: GPL-3.0-only
#
{
  lib,
  hostname,
  config,
  inputs,
  pkgs,
  ...
}: let
  isPersonal =
    hostname
    == "NEO-LINUX"
    || hostname == "DEUSEX-LINUX"
    || hostname == "MJOLNIR-LINUX"
    || hostname == "MORPHEUS-LINUX";
  isDeltaZero = hostname == "delta-zero";
in
  {
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
        if false
        then
          (with inputs; [
            nixfigs-work-container.nixosModules.default
          ])
        else []
      )
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
      man.cache.enable = true;
    };

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

      # Block monitor's internal Prolific hub - prevents touchscreen/trackpad from enumerating
      ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="067b", ATTRS{idProduct}=="2586", ATTR{authorized}="0"
      # WingCool touchscreen
      ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="27c6", ATTRS{idProduct}=="0529", ATTR{authorized}="0"
      # Fake Magic Trackpad (touch pointer device)
      ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="05ac", ATTRS{idProduct}=="0265", ATTR{authorized}="0"
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
  // lib.optionalAttrs false {
    nixfigs.workBrowserContainer = {
      enable = true;
      vpnConfigPath = config.age.secrets.ct_vpn_config.path;
      vpnCredentialsPath = config.age.secrets.ct_vpn_creds.path;
      chromiumWorkDomain = "codethink.co.uk";
    };
    environment.systemPackages = with pkgs; [waypipe];
  }
