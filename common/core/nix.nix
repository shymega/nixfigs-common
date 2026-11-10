# SPDX-FileCopyrightText: 2023-2026 Dom 'shymega' Rodriguez <shymega@shymega.org.uk>
#
# SPDX-License-Identifier: Apache-2.0
{
  inputs,
  lib,
  libx,
  pkgs,
  config,
  options,
  ...
}: let
  inherit (libx) isDarwin;
in {
  programs.ssh = {
    extraConfig = ''
      Host eu.nixbuild.net
        HostName eu.nixbuild.net
        PubkeyAcceptedKeyTypes ssh-ed25519
        ServerAliveInterval 60
        IdentityFile ${config.age.secrets."nixbuild_ssh_priv_key".path}
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
      distributedBuilds = false;
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
      settings = rec {
        accept-flake-config = true;
        auto-allocate-uids = true;
        extra-platforms = config.boot.binfmt.emulatedSystems;
        allowed-users = ["@wheel"];
        build-users-group = "nixbld";
        builders-use-substitutes = true;
        download-attempts = 5;
        download-buffer-size = 67108864;
        keep-going = true;
        trusted-users = [
          "root"
          "@wheel"
        ];
        sandbox = true;
        substituters = lib.mkForce [
          "https://atuin.cachix.org?priority=10"
          "https://cache.flox.dev?priority=10"
          "https://cache.nixos.org/?priority=5"
          "https://hyprland.cachix.org/?priority=10"
          "https://install.determinate.systems"
          "https://nix-community.cachix.org/?priority=10"
          "https://numtide.cachix.org/?priority=10"
          "https://pre-commit-hooks.cachix.org/?priority=10"
        ];
        trusted-public-keys = lib.mkForce [
          "atuin.cachix.org-1:aNJ8IU+udXIYNtrF+LHH8yIzXqgmva4hVnuHq2REgK0="
          "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
          "floxhub-1:0QOAlcobcEvq1mqEf4qAYCaWnTTOXpyoRv/PmqfSixM="
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "nixbuild.net/VNUM6K-1:ha1G8guB68/E1npRiatdXfLZfoFBddJ5b2fPt3R9JqU="
          "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
          "pre-commit-hooks.cachix.org-1:Pkk3Panw5AW24TOv6kz3PvLhlH8puAsJTBbOPmBo7Rc="
        ];
        experimental-features = [
          "auto-allocate-uids"
          "cgroups"
          "nix-command"
          "flakes"
        ];
        connect-timeout = lib.mkForce 90;
        http-connections = 12;
        max-substitution-jobs = 12;
        warn-dirty = false;
        cores = 4;
        eval-cores = 2;
        lazy-trees = true;
        max-jobs = "4";
        system-features = [
          "kvm"
          "nixos-test"
          "big-parallel"
          "uid-range"
        ];
      };
      extraOptions = ''
        gc-keep-outputs = false
        gc-keep-derivations = false
        min-free = ${toString (100 * 1024 * 1024)}
        max-free = ${toString (1024 * 1024 * 1024)}
        !include ${config.age.secrets.nix_conf_access_tokens.path}
      '';
      package = let
        determinateNixPkg = let
          inherit (inputs.determinate.inputs.nix.packages.${pkgs.stdenv.hostPlatform.system}) default;
          detnixPatch = pkgs.fetchpatch {
            url = "https://github.com/user-attachments/files/27144728/detnix.patch";
            hash = "sha256-oEeOigJJrT4vVKkGddqwpjhT+6b/pJC/7GPbe2G2OAs=";
          };
          # The `ps` nix-functional-test fails outside of a real process tree
          # (e.g. in our build sandboxes), so skip it.
          skipPsFunctionalTestPatch = ./nix-functional-tests-skip-ps.patch;
        in
          default.appendPatches [
            detnixPatch
            skipPsFunctionalTestPatch
          ];
      in
        lib.mkForce determinateNixPkg;
      registry = lib.mkForce {
        n.flake = inputs.nixfigs-common;
        nixpkgs.flake = inputs.nixfigs-common;
        nu.flake = inputs.nixpkgs-unstable;
        shypkgs.flake = inputs.shypkgs-public;
        unstable.flake = inputs.nixpkgs-unstable;
      };
      optimise = {
        automatic = true;
        dates = ["06:00"];
      };
      nixPath =
        lib.mkForce
        (options.nix.nixPath.default
          ++ lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry);
      gc = {
        automatic = true;
        options = "--delete-older-than 14d";
      };
    }
    // lib.optionalAttrs (!isDarwin) {
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
