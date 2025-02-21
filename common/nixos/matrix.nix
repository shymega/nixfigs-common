# SPDX-FileCopyrightText: 2024 Dom Rodriguez <shymega@shymega.org.uk
#
# SPDX-License-Identifier: GPL-3.0-only
{
  lib,
  libx,
  config,
  ...
}:
with lib; let
  inherit (libx.roleUtils) checkRoles;
  enabled = checkRoles ["personal"] config.nixfigs.meta.rolesEnabled;
in {
  config = mkIf enabled {
    services.pantalaimon-headless.instances.rnetMatrix = {
      homeserver = "https://matrix.rodriguez.org.uk";
      listenAddress = "127.0.0.1";
      listenPort = 8008;
    };
  };
}
