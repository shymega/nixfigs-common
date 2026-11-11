# SPDX-FileCopyrightText: 2023-2026 Dom 'shymega' Rodriguez <shymega@shymega.org.uk>
#
# SPDX-License-Identifier: Apache-2.0
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
    pkgsFor = forEachSystem genPkgs;
  in {
    inherit (inputs.nixfigs-pkgs) overlays nixpkgs-config;
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
        pkgs = pkgsFor.${system};
      in
        import inputs.nixfigs-helpers.helpers.devShells {inherit pkgs self system;}
    );
    legacyPackages = pkgsFor;
    common = {
      core = ./common/core;
      nixos = ./common/nixos;
      darwin = ./common/darwin;
    };
  };
  inputs = {
    nixpkgs.follows = "nixfigs-pkgs/nixpkgs";
    nixpkgs-unstable.follows = "nixfigs-pkgs/nixpkgs-unstable";
    nixpkgs-master.follows = "nixfigs-pkgs/nixpkgs-master";
    nixpkgs-shymega.follows = "nixfigs-pkgs/nixpkgs-shymega";
    nixfigs-helpers = {
      url = "github:shymega/nixfigs-helpers";
      inputs.agenix.follows = "agenix";
      inputs.flake-compat.follows = "flake-compat";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixfigs-pkgs = {
      url = "github:shymega/nixfigs-pkgs";
      inputs.nix-alien.follows = "nix-alien";
      inputs.nixfigs-helpers.follows = "nixfigs-helpers";
      inputs.nur.follows = "nur";
    };
    nixfigs-networks = {
      url = "github:shymega/nixfigs-networks";
      inputs.nixfigs-helpers.follows = "nixfigs-helpers";
      inputs.nixfigs-pkgs.follows = "nixfigs-pkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-alien = {
      url = "github:thiagokokada/nix-alien";
      inputs.flake-compat.follows = "flake-compat";
    };
    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.home-manager.follows = "home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland.follows = "nixfigs-pkgs/hyprnix/hyprland";
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins?ref=v0.56.0";
      inputs.hyprland.follows = "hyprland"; # Prevents version mismatch.
    };
  };
}
