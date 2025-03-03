# SPDX-FileCopyrightText: 2024 Dom Rodriguez <shymega@shymega.org.uk
#
# SPDX-License-Identifier: GPL-3.0-only
{
  inputs,
  lib,
  libx,
  pkgs,
  config,
  options,
  username,
  ...
}: let
  inherit (libx) isDarwin isForeignNix isNixOS;
in {
  environment.etc."nix/overlays-compat/overlays.nix".text = ''
    final: prev:
    with prev.lib;
    let overlays = builtins.attrValues (builtins.getFlake "path:/etc/nixos").outputs.overlays; in
      foldl' (flip extends) (_: prev) overlays final
  '';

  programs.ssh = {
    extraConfig = ''
      Host eu.nixbuild.net
        HostName eu.nixbuild.net
        PubkeyAcceptedKeyTypes ssh-ed25519
        ServerAliveInterval 60
        IPQoS throughput
        ${
        if libx.hasSuffix "-darwin" pkgs.system
        then
          if
            builtins.pathExists "${
              config.users.users.${username}.home
            }/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
          then "IdentityAgent ${
            config.users.users.${username}.home
          }/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
          else "IdentityFile /run/agenix/nixbuild_ssh_priv_key"
        else if builtins.pathExists "${config.users.users.${username}.home}/.1password/agent.sock"
        then "IdentityAgent ${config.users.users.${username}.home}/.1password/agent.sock"
        else "IdentityFile /run/agenix/nixbuild_ssh_priv_key"
      }
    '';
    knownHosts = {
      nixbuild = {
        hostNames = ["eu.nixbuild.net"];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPIQCZc54poJ8vqawd8TraNryQeJnvH1eLpIDgbiqymM";
      };
    };
  };

  nix =
    {
      distributedBuilds = true;
      buildMachines = [
        {
          hostName = "eu.nixbuild.net";
          sshUser = "${config.networking.hostName}-build-client";
          systems = [
            "aarch64-linux"
            "armv7l-linux"
            "i686-linux"
            "x86_64-linux"
          ];
          maxJobs = 4;
          supportedFeatures = [
            "benchmark"
            "big-parallel"
          ];
          protocol = "ssh-ng";
        }
      ];
      settings = {
        accept-flake-config = true;
        extra-platforms = config.boot.binfmt.emulatedSystems;
        allowed-users = ["@wheel"];
        build-users-group = "nixbld";
        builders-use-substitutes = true;
        trusted-users = [
          "root"
          "@wheel"
        ];
        sandbox = isForeignNix || isNixOS;
        substituters = [
          "https://cache.dataaturservice.se/spectrum/?priority=50"
          "https://cache.nixos.org/?priority=10"
          "https://deploy-rs.cachix.org/?priority=10"
          "https://devenv.cachix.org/?priority=5"
          "https://nix-community.cachix.org/?priority=5"
          "https://nix-gaming.cachix.org/?priority=5"
          "https://nix-on-droid.cachix.org/?priority=5"
          "https://numtide.cachix.org/?priority=5"
          "https://pre-commit-hooks.cachix.org/?priority=5"
          "ssh://eu.nixbuild.net?priority=50"
        ];
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "deploy-rs.cachix.org-1:xfNobmiwF/vzvK1gpfediPwpdIP0rpDV2rYqx40zdSI="
          "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
          "nix-on-droid.cachix.org-1:56snoMJTXmDRC1Ei24CmKoUqvHJ9XCp+nidK7qkMQrU="
          "nixbuild.net/VNUM6K-1:ha1G8guB68/E1npRiatdXfLZfoFBddJ5b2fPt3R9JqU="
          "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
          "pre-commit-hooks.cachix.org-1:Pkk3Panw5AW24TOv6kz3PvLhlH8puAsJTBbOPmBo7Rc="
          "spectrum-os.org-2:foQk3r7t2VpRx92CaXb5ROyy/NBdRJQG2uX2XJMYZfU="
        ];
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        connect-timeout = lib.mkForce 90;
        http-connections = 128;
        max-substitution-jobs = 128;
        warn-dirty = false;
        cores = 0;
        max-jobs = "auto";
        system-features = [
          "kvm"
          "nixos-test"
          "big-parallel"
        ];
      };
      extraOptions = ''
        gc-keep-outputs = false
        gc-keep-derivations = false
        min-free = ${toString (100 * 1024 * 1024)}
        max-free = ${toString (1024 * 1024 * 1024)}
        !include ${config.age.secrets.nix_conf_access_tokens.path}
      '';
      registry = rec {
        nixpkgs.flake = inputs.nixpkgs;
        n.flake = nixpkgs.flake;
        home-manager.flake = inputs.home-manager;
        unstable.flake = inputs.nixpkgs-unstable;
        shynixpkgs.flake = inputs.nixpkgs-shymega;
        shypkgs.flake = inputs.shypkgs-public // inputs.shypkgs-public;
      };
      optimise = {
        automatic = true;
        dates = ["06:00"];
      };
      package = pkgs.nix;
      nixPath = options.nix.nixPath.default; # ++ [ "nixpkgs-overlays=/etc/nix/overlays-compat/" ];
      gc = {
        automatic = true;
        options = "--delete-older-than 14d";
      };
    }
    // lib.optionalAttrs (isForeignNix || isNixOS) {
      daemonCPUSchedPolicy = "batch";
      daemonIOSchedPriority = 5;
      gc.dates = "06:00";
    }
    // lib.optionalAttrs isDarwin {
      daemonIOLowPriority = true;
      gc.interval = {
        Hour = 6;
        Minute = 0;
      };
    };
}
