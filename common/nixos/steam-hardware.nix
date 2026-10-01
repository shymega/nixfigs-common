# SPDX-FileCopyrightText: 2023-2026 Dom 'shymega' Rodriguez <shymega@shymega.org.uk>
#
# SPDX-License-Identifier: Apache-2.0
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
