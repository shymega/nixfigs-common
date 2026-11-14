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
  # background. Merely restarting dlm.service doesn't reproduce what a
  # physical unplug/replug does: evdi's kernel driver keeps the wedged
  # DRM minor and painter connection alive across a userspace restart, so
  # the compositor never sees the output go away and come back, and the
  # only previously-known recovery was a full `loginctl terminate-user`
  # (which just SIGKILLs the wedged process once systemd's stop timeout
  # expires) or physically cycling the dock. Soft-reset the dock's own
  # USB device instead -- unbind/rebind forces the kernel to tear down
  # and recreate the evdi device exactly as an actual unplug would;
  # dlm.service then starts itself again via the existing
  # add-triggered udev rule.
  evdi-watchdog = pkgs.writeShellScriptBin "evdi-watchdog" ''
    #!${pkgs.runtimeShell}

    threshold=3
    window=30
    cooldown=60
    last_reset=0
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
      if [ "$count" -ge "$threshold" ] && [ $((now - last_reset)) -ge "$cooldown" ]; then
        echo "evdi-watchdog: $count evdi failures within ''${window}s, soft-resetting DisplayLink dock"

        dl_device=""
        for vendor_file in /sys/bus/usb/devices/*/idVendor; do
          [ -e "$vendor_file" ] || continue
          read -r vendor <"$vendor_file"
          if [ "$vendor" = "17e9" ]; then
            dl_device_dir="''${vendor_file%/*}"
            dl_device="''${dl_device_dir##*/}"
            break
          fi
        done

        ${getExe' pkgs.systemd "systemctl"} stop dlm.service
        if [ -n "$dl_device" ]; then
          echo "$dl_device" >/sys/bus/usb/drivers/usb/unbind
          ${getExe' pkgs.coreutils "sleep"} 1
          echo "$dl_device" >/sys/bus/usb/drivers/usb/bind
        else
          echo "evdi-watchdog: no USB device with idVendor 17e9 found, falling back to dlm.service restart"
          ${getExe' pkgs.systemd "systemctl"} start dlm.service
        fi

        last_reset=$now
        count=0
      fi
    done
  '';
in {
  config = mkIf enabled {
    systemd.services.evdi-watchdog = {
      description = "Soft-reset the DisplayLink dock's USB device when evdi failures repeat";
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
