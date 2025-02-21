# SPDX-FileCopyrightText: 2024 Dom Rodriguez <shymega@shymega.org.uk
#
# SPDX-License-Identifier: GPL-3.0-only
{
  lib,
  libx,
  hostRoles,
  config,
  ...
}:
with lib; let
  enabled = libx.roleUtils.checkRoles ["personal"] hostRoles;
in {
  config = mkIf enabled {
    services.pantalaimon-headless.instances.rnetMatrix = {
      homeserver = "https://matrix.rodriguez.org.uk";
      listenAddress = "127.0.0.1";
      listenPort = 8008;
    };
  };
}
