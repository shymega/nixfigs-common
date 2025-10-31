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

    ${getExe pkgs.ryzenadj} --tctl-temp=97 --stapm-limit="$WATTAGE"000 \
      --fast-limit="$WATTAGE"000 --slow-limit="$WATTAGE"000 \
      --vrmmax-current="$WATTAGE"000
  '';
in {
  environment.systemPackages = singleton amdcpu-adjust;
  systemd = {
    services = {
      power-maximum-tdp = optionalAttrs (hostName == "DEUSEX-LINUX") {
        description = "Change TDP to maximum TDP when on AC power";
        wantedBy = [
          "multi-user.target"
          "ac.target"
        ];
        unitConfig = {
          RefuseManualStart = true;
          Requires = "ac.target";
        };
        path = with pkgs; [ryzenadj];
        serviceConfig.Type = "oneshot";
        script = ''
          ${getExe amdcpu-adjust} 28;
        '';
      };

      power-saving-tdp = optionalAttrs (hostName == "DEUSEX-LINUX") {
        description = "Change TDP to power saving TDP when on battery power";
        wantedBy = ["battery.target"];
        unitConfig = {
          RefuseManualStart = true;
        };
        path = with pkgs; [ryzenadj];
        serviceConfig.Type = "oneshot";
        script = ''
          ${getExe amdcpu-adjust} 5;
        '';
      };

      powertop = optionalAttrs (hostName == "TWINS-LINUX" || hostName == "DEUSEX-LINUX") {
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
