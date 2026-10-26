# SPDX-FileCopyrightText: 2023-2026 Dom 'shymega' Rodriguez <shymega@shymega.org.uk>
#
# SPDX-License-Identifier: Apache-2.0
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
    == "HEIMDALL-LINUX"
    || hostname == "MJOLNIR-LINUX"
    || hostname == "FREYR-LINUX"
    || hostname == "THIRA-LINUX";
  isWorkPersonal = hostname == "HEIMDALL-LINUX" || hostname == "MJOLNIR-LINUX" || hostname == "FREYR-LINUX";
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
        ./specialisations.nix
        ./systemd-initrd.nix
        ./utils
      ]
      ++ (
        with inputs; [
          determinate.nixosModules.default
        ]
      )
      ++ (
        if isWorkPersonal
        then
          (with inputs; [
            nixfigs-work-container.nixosModules.default
          ])
        else []
      )
      ++ (
        if isPersonal
        then [
          ./custom-systemd-units
          ./dovecot2.nix
          ./graphical.nix
          ./impermanence.nix
          ./postfix.nix
          ./steam-hardware.nix
          ./xdg.nix
          ({pkgs, ...}: {
            environment.systemPackages = [
              inputs.flox.packages.${pkgs.stdenv.hostPlatform.system}.default
            ];
          })
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
      # NixOS ships a baseline PAM service for swaylock out of the box, but
      # not for hyprlock. Without this, hyprlock's pam_start() falls through
      # to /etc/pam.d/other, which unconditionally denies -- so anything
      # relying on a real PAM/session handshake on unlock (e.g. 1Password's
      # "unlock using system authentication") silently fails and falls back
      # to its own prompt instead.
      pam.services.hyprlock = {};
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

      # WFH - Ploopy, Keychron Q11, Wireless Mouse receiver - turn off USB suspend
      ACTION=="add|change", SUBSYSTEM=="usb", ATTRS{idVendor}=="1bcf", ATTRS{idProduct}=="0005", ATTR{power/autosuspend}="-1"
      ACTION=="add|change", SUBSYSTEM=="usb", ATTRS{idVendor}=="3434", ATTRS{idProduct}=="01e0", ATTR{power/autosuspend}="-1"
      ACTION=="add|change", SUBSYSTEM=="usb", ATTRS{idVendor}=="25a7", ATTRS{idProduct}=="fa61", ATTR{power/autosuspend}="-1"

      # KVM - active input stub
      SUBSYSTEM=="usb", ACTION=="add|change|remove", ATTR{idVendor}=="13ba", ATTR{idProduct}=="0018",  SYMLINK+="currkvm", TAG+="systemd"

      # workstation - keyboard & mouse suspension.
      ACTION=="add|change", SUBSYSTEM=="usb", ATTRS{idVendor}=="05ac", ATTRS{idProduct}=="024f", ATTR{power/autosuspend}="-1"
      ACTION=="add|change", SUBSYSTEM=="usb", ATTRS{idVendor}=="5043", ATTRS{idProduct}=="5c46", ATTR{power/autosuspend}="-1"

      # Block monitor's internal Prolific hub - prevents touchscreen/trackpad from enumerating
      ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="067b", ATTRS{idProduct}=="2586", ATTR{authorized}="0"
      # WingCool touchscreen
      ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="27c6", ATTRS{idProduct}=="0529", ATTR{authorized}="0"
      # Fake Magic Trackpad (touch pointer device)
      ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="05ac", ATTRS{idProduct}=="0265", ATTR{authorized}="0"

      # Sonix USB 2.0 Camera - disable autosuspend, KVM/hub chain already causes
      # intermittent drops; suspending on top of that makes it worse
      ACTION=="add|change", SUBSYSTEM=="usb", ATTRS{idVendor}=="0c45", ATTRS{idProduct}=="6366", ATTR{power/autosuspend}="-1"
    '';

    users.mutableUsers = false;
    services.atd.enable = true;
    programs.nix-ld.enable = true;
    programs.java.binfmt = true;
    services.incron.enable = true;

    # This is from https://emudhra.we-have-a-problem.com/
    security.pki.caCertificateBlacklist = [
      "Comodo AAA Services root"
      "emSign ECC Root CA - G3"
      "emSign Root CA - C1"
      "emSign ECC Root CA - C3"
    ];
  }
  // lib.optionalAttrs isWorkPersonal {
    nixfigs.workBrowserContainer = {
      enable = true;
      embedSecrets = false;
      vpnConfigPath = config.age.secrets.ct_vpn_config.path;
      vpnCredentialsPath = config.age.secrets.ct_vpn_creds.path;
      chromiumWorkDomain = "codethink.co.uk";
    };
    environment.systemPackages = with pkgs; [waypipe];
  }
