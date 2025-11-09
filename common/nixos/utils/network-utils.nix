# SPDX-FileCopyrightText: 2024 Dom Rodriguez <shymega@shymega.org.uk>
#
# SPDX-License-Identifier: GPL-3.0-only
{
  pkgs,
  lib,
  ...
}: {
  environment.systemPackages = let
    inherit (lib) getExe getExe';
    inherit (pkgs) writeScriptBin;
    inherit (pkgs.stdenv) shell;
    nmcli = getExe' pkgs.networkmanager "nmcli";
  in [
    (writeScriptBin "net-type" ''
      #! ${shell}
      set -eu

      exec ${nmcli} \
        networking connectivity
    '')
    (writeScriptBin "net-metered" ''
      #! ${shell}
      set -eu

      DEVICE=$(${nmcli} device status | grep wifi | grep connected \
        ${getExe' pkgs.coreutils "head"} -1 | ${getExe pkgs.gawk} '{print $1}')
      CURRENT_CONNECTION=$(${nmcli} -t -f GENERAL.CONNECTION --mode tabular device show "$DEVICE")

      exec ${nmcli} -g connection.metered connection show "$CURRENT_CONNECTION" | ${getExe' pkgs.coreutils "head"} -n1
    '')
    (writeScriptBin "net-current-profile" ''
      #! ${shell}
      set -eu

      exec ${nmcli} connection show --active | ${getExe' pkgs.coreutils "head"} -2 | ${getExe' pkgs.coreutils "tail"} -1 | ${getExe pkgs.gawk} '{print $1}'
    '')
    (writeScriptBin "net-connected-profiles" ''
      #! ${shell}
      set -eu

      exec ${nmcli} -t connection show --active | ${getExe pkgs.gawk} -F: '{print $2}'
    '')
  ];
}
