# SPDX-FileCopyrightText: 2024 Dom Rodriguez <shymega@shymega.org.uk
#
# SPDX-License-Identifier: GPL-3.0-only
#
{
  lib,
  libx,
  hostRoles,
  config,
  ...
}:
with lib; let
  enabled = libx.roleUtils.checkRoles ["gaming" "steam-deck" "jovian"] hostRoles;
in {
  config = mkIf enabled {
    hardware.steam-hardware.enable = true;
  };
}
