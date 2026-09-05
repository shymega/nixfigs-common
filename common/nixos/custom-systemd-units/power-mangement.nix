# SPDX-FileCopyrightText: 2024 Dom Rodriguez <shymega@shymega.org.uk
#
# SPDX-License-Identifier: GPL-3.0-only
#
{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (config.networking) hostName;
  inherit (lib) getExe getExe' optionalAttrs singleton;
  amdcpu-adjust = pkgs.writeShellScriptBin "amdcpu-adjust" ''
    #! ${getExe pkgs.bash}

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
      powertop = optionalAttrs (hostName == "TYR-LINUX" || hostName == "HEIMDALL-LINUX" || hostName == "FREYR-LINUX" || hostName == "LOKI-LINUX" || hostName == "THIRA-LINUX" || hostName == "KRATOS-LINUX") {
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
