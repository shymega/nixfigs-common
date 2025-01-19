# SPDX-FileCopyrightText: 2024 Dom Rodriguez <shymega@shymega.org.uk
#
# SPDX-License-Identifier: GPL-3.0-only
#
{
  lib,
  libx,
  config,
  ...
}:
with lib; let
  inherit (libx.roleUtils) checkRoles;
  enabled = checkRoles ["gaming" "steam-deck" "jovian"] config.nixfigs.meta.rolesEnabled;
in {
  config = mkIf enabled {
    hardware.steam-hardware.enable = true;
  };
}
