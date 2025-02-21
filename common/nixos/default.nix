# SPDX-FileCopyrightText: 2024 Dom Rodriguez <shymega@shymega.org.uk
#
# SPDX-License-Identifier: GPL-3.0-only
#
{
  lib,
  pkgs,
  hostname,
  ...
}: {
  imports =
    [
      ./appimage.nix
      ./bluetooth.nix
      ./custom-systemd-units
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
      if
        hostname
        == "NEO-LINUX"
        || hostname == "MORPHEUS-LINUX"
        || hostname == "TWINS-LINUX"
        || hostname == "TRINITY-LINUX"
        || lib.hasInfix "DEUSEX" hostname
      then [
        ./automount.nix
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
      if hostname == "delta-zero" || hostname == "DELTA-ZERO"
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
      # allowedUDPPorts = [ config.services.tailscale.port ];
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

  system = {
    extraSystemBuilderCmds = ''
      ln -sv ${pkgs.path} $out/nixpkgs
    '';
  };

  systemd = {
    network.wait-online.anyInterface = false;
    services.tailscaled = {
      after = ["network-online.target"];
      wants = ["network-online.target"];
    };
  };

  services.udev.extraRules = ''
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="5548", ATTRS{idProduct}=="6670", GROUP="users", TAG+="uaccess"

    # XR Glasses Rules:
    SUBSYSTEM=="usb", ACTION=="add", ATTRS{idVendor}=="1bbb", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="usb", ACTION=="add", ATTRS{idVendor}=="04d2", MODE="0660", TAG+="uaccess"
    KERNEL=="uinput", SUBSYSTEM=="misc" MODE="0660", TAG+="uaccess", OPTIONS+="static_node=uinput"
    SUBSYSTEM=="usb", ACTION=="add", ATTRS{idVendor}=="35ca", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="usb", KERNEL=="hiddev[0-9]*", ATTRS{idVendor}=="35ca", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="tty", KERNEL=="ttyACM[0-9]*", ATTRS{idVendor}=="35ca", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="hidraw", KERNEL=="hidraw[0-9]*", ATTRS{idVendor}=="35ca", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="usb", ACTION=="add", ATTR{idVendor}=="3318", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="input", KERNEL=="event[0-9]*", ATTRS{idVendor}=="3318", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="sound", KERNEL=="pcmC[0-9]D[0-9]p", ATTRS{idVendor}=="3318", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="sound", KERNEL=="controlC[0-9]", ATTRS{idVendor}=="3318", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="hidraw", KERNEL=="hidraw[0-9]*", ATTRS{idVendor}=="3318", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="usb", KERNEL=="hiddev[0-9]*", ATTRS{idVendor}=="3318", MODE="0660", TAG+="uaccess"
  '';

  users.mutableUsers = false;
  services.atd.enable = true;
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
