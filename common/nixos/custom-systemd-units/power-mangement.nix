# SPDX-FileCopyrightText: 2023-2026 Dom 'shymega' Rodriguez <shymega@shymega.org.uk>
#
# SPDX-License-Identifier: Apache-2.0
#
{
  pkgs,
  lib,
  ...
}: let
  inherit (lib) getExe getExe' optionalAttrs singleton;
  amdcpu-adjust = pkgs.writeShellScriptBin "amdcpu-adjust" ''
    #!${pkgs.runtimeShell}

    WATTAGE=$1

    if [ -z $WATTAGE ]; then
      echo "Not enough params." && exit 1
    fi

    ${getExe pkgs.ryzenadj} --stapm-limit="$WATTAGE"000 \
      --fast-limit="$WATTAGE"000 --slow-limit="$WATTAGE"000
  '';
in {
  environment.systemPackages = singleton amdcpu-adjust;
  systemd = {
    services = {
      powertop = optionalAttrs false {
        description = "Auto-tune Power Management with powertop";
        unitConfig = {
          RefuseManualStart = true;
        };
        wantedBy = [
          "multi-user.target"
          "battery.target"
        ];
        path = with pkgs; [powertop];
        serviceConfig.Type = "oneshot";
        script = ''
          ${getExe pkgs.powertop} --auto-tune
        '';
      };

      "inhibit-suspension@" = {
        description = "Inhibit suspension for one hour";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${getExe' pkgs.systemd "systemd-inhibit"} --what=sleep --why=PreventSuspension --who=system ${getExe' pkgs.coreutils "sleep"} %ih";
        };
      };
    };
  };
}
