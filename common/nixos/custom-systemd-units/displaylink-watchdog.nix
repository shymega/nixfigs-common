# SPDX-FileCopyrightText: 2023-2026 Dom 'shymega' Rodriguez <shymega@shymega.org.uk>
#
# SPDX-License-Identifier: Apache-2.0
#
{
  pkgs,
  lib,
  config,
  ...
}:
with lib; let
  enabled = elem "displaylink" config.services.xserver.videoDrivers;

  # DisplayLinkManager (dlm.service) occasionally wedges itself mid-session
  # (observed alongside kernel "evdi_painter_connect: Double connect"
  # warnings) and keeps running but stops servicing frames. evdi's kernel
  # driver then never gets a flip-done completion for its outputs, which
  # blocks aquamarine's synchronous commit-wait and freezes the whole
  # compositor -- cursor and input included, not just the DisplayLink
  # panels -- while DisplayLinkManager quietly burns CPU in the
  # background. The only previously-known recovery was a full `loginctl
  # terminate-user`, which just SIGKILLs the wedged process as collateral
  # once systemd's stop timeout expires. Watch for the kernel's own
  # timeout errors instead and restart dlm.service directly as soon as
  # they repeat, instead of waiting on a full session teardown.
  evdi-watchdog = pkgs.writeShellScriptBin "evdi-watchdog" ''
    #!${pkgs.runtimeShell}

    threshold=3
    window=30
    cooldown=60
    last_restart=0
    count=0
    window_start=0

    ${getExe' pkgs.systemd "journalctl"} -kf -n 0 \
      -g 'evdi.*(flip_done timed out|commit wait timed out|Double connect)' |
    while IFS= read -r _line; do
      now=$(${getExe' pkgs.coreutils "date"} +%s)
      if [ $((now - window_start)) -gt "$window" ]; then
        window_start=$now
        count=0
      fi
      count=$((count + 1))
      if [ "$count" -ge "$threshold" ] && [ $((now - last_restart)) -ge "$cooldown" ]; then
        echo "evdi-watchdog: $count evdi failures within ''${window}s, restarting dlm.service"
        ${getExe' pkgs.systemd "systemctl"} restart dlm.service
        last_restart=$now
        count=0
      fi
    done
  '';
in {
  config = mkIf enabled {
    systemd.services.evdi-watchdog = {
      description = "Restart dlm.service when evdi flip-done timeouts repeat";
      after = ["dlm.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        ExecStart = getExe evdi-watchdog;
        Restart = "always";
        RestartSec = 5;
      };
    };
  };
}
