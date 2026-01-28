# SPDX-FileCopyrightText: 2024 Dom Rodriguez <shymega@shymega.org.uk
#
# SPDX-License-Identifier: GPL-3.0-only
{
  description = "Common settings for my NixOS flakes";

  outputs = inputs: let
    inherit (inputs) self;
    genPkgs = system:
      import inputs.nixpkgs {
        inherit system;
        overlays = builtins.attrValues self.overlays;
        config = self.nixpkgs-config;
      };

    systems = [
      "x86_64-linux"
      "aarch64-linux"
    ];

    treeFmtEachSystem = f: inputs.nixpkgs.lib.genAttrs systems (system: f inputs.nixpkgs.legacyPackages.${system});
    treeFmtEval = treeFmtEachSystem (
      pkgs:
        inputs.nixfigs-helpers.inputs.treefmt-nix.lib.evalModule pkgs inputs.nixfigs-helpers.helpers.formatter
    );

    forEachSystem = inputs.nixpkgs.lib.genAttrs systems;
  in {
    inherit (inputs.nixfigs-pkgs) overlays packages nixpkgs-config;
    # for `nix fmt`
    formatter = treeFmtEachSystem (pkgs: treeFmtEval.${pkgs.stdenv.hostPlatform.system}.config.build.wrapper);
    # for `nix flake check`
    checks =
      treeFmtEachSystem (pkgs: {
        formatting = treeFmtEval.${pkgs}.config.build.wrapper;
      })
      // forEachSystem (system: {
        pre-commit-check = import "${inputs.nixfigs-helpers.helpers.checks}" {
          inherit self system;
          inherit (inputs.nixfigs-helpers) inputs;
          inherit (inputs.nixpkgs) lib;
        };
      });
    devShells = forEachSystem (
      system: let
        pkgs = genPkgs system;
      in
        import inputs.nixfigs-helpers.helpers.devShells {inherit pkgs self system;}
    );
    common = {
      core = ./common/core;
      nixos = ./common/nixos;
      darwin = ./common/darwin;
    };
  };
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";
    nixpkgs-shymega.url = "github:shymega/nixpkgs?ref=shymega/staging";
    nixfigs-helpers.url = "github:shymega/nixfigs-helpers";
    nixfigs-pkgs.url = "github:shymega/nixfigs-pkgs";
    nixfigs-networks.url = "github:shymega/nixfigs-pkgs";
    flake-registry = {
      url = "github:NixOS/flake-registry";
      flake = false;
    };
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix?ref=0.15.0";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
        darwin.follows = "nix-darwin";
      };
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur.url = "github:nix-community/NUR";
    nix-alien = {
      url = "github:thiagokokada/nix-alien";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nix-index-database.follows = "nix-index-database";
      };
    };
    flake-utils.url = "github:numtide/flake-utils?ref=v1.0.0";
    android-nixpkgs = {
      url = "github:tadfisher/android-nixpkgs/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dzr-taskwarrior-recur.url = "github:shymega/dzr-taskwarrior-recur";
    impermanence.url = "github:nix-community/impermanence";
    nm2nix.url = "github:Janik-Haag/nm2nix";
    hyprland = {
      url = "github:hyprwm/Hyprland?ref=v0.53.3";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland"; # Prevents version mismatch.
    };
  };
}
