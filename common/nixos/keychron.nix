# SPDX-FileCopyrightText: 2024 Dom Rodriguez <shymega@shymega.org.uk
#
# SPDX-License-Identifier: GPL-3.0-only
#
{
  config,
  lib,
  libx,
  pkgs,
  ...
}: let
  inherit (libx) isNixOS;
in
  with lib; {
    options = {
      nixfigs.input.keyboard.keychron.enable = mkOption {
        type = with types; bool;
        description = "Enable Linux-specific mitigations for the Keychron keyboard.";
        default = isNixOS;
      };
    };
    config = mkIf true {
      boot.extraModprobeConfig = ''
        options hid_apple fnmode=0
      '';
      environment.systemPackages = with pkgs; [
        via
      ];
      services.udev.packages = [pkgs.via];
      hardware.keyboard.qmk.enable = true;
    };
  }
