# SPDX-FileCopyrightText: 2024 Dom Rodriguez <shymega@shymega.org.uk
#
# SPDX-License-Identifier: GPL-3.0-only

#

{ inputs
, lib
, pkgs
, hostname
, ...
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
      ./sound.nix
      ./networking.nix
      ./systemd-initrd.nix
      ./utils
    ]
    ++ (
      if hostname == "NEO-LINUX" || hostname == "MORPHEUS-LINUX" || hostname == "TWINS-LINUX" then
        [
          ./automount.nix
          ./graphical.nix
          ./impermanence.nix
          ./steam-hardware.nix
          ./matrix.nix
          ./postfix.nix
          ./davmail.nix
          ./dovecot2.nix
          inputs.nix-index-database.nixosModules.nix-index
          #          inputs.stylix.nixosModules.stylix
        ]
      else
        [ ]
    ) ++ (
      if hostname == "MORPHEUS-LINUX" then
        [
          ./backups.nix
        ]
      else
        [ ]
    ) ++ (
      if hostname == "DELTA-ZERO" then
        [
          ./davmail.nix
          ./dovecot2.nix
        ]
      else
        [ ]
    );

  boot.kernelParams = [ "log_buf_len=10M" ];

  documentation = {
    dev.enable = true;
    man.generateCaches = true;
  };

  i18n.defaultLocale = "en_GB.UTF-8";

  networking = {
    firewall = {
      #      trustedInterfaces = [ "tailscale0" ];
      #      allowedUDPPorts = [ config.services.tailscale.port ];
    };
  };

  programs = {
    command-not-found.enable = false;
    mosh.enable = true;
    zsh.enableGlobalCompInit = false;
  };

  security = {
    pam.services.sudo.u2fAuth = true;
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
      after = [
        "network-online.target"
      ];
      wants = [
        "network-online.target"
      ];
    };
  };

  services.udev.extraRules = ''
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="5548", ATTRS{idProduct}=="6670", GROUP="users", TAG+="uaccess"
  '';

  users.mutableUsers = false;
}
