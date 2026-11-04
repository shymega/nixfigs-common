# SPDX-FileCopyrightText: 2023-2026 Dom 'shymega' Rodriguez <shymega@shymega.org.uk>
#
# SPDX-License-Identifier: Apache-2.0
#
{
  pkgs,
  lib,
  libx,
  config,
  ...
}:
with lib; let
  inherit (libx.roleUtils) checkRoles;
  enabled = checkRoles ["workstation"] config.nixfigs.meta.rolesEnabled;
  # evdi (DisplayLink) doesn't reliably signal atomic commit completion
  # behind the PRIME-sync nvidia/intel hybrid pipeline on these hosts, which
  # times out the flip and leaves the panel on "No Signal". Harmless no-op
  # on other hosts since WLR_DRM_NO_ATOMIC/KWIN_DRM_NO_AMS only matter to
  # compositors that actually read them.
  needsNoAtomicDrm = builtins.elem config.networking.hostName ["MJOLNIR-LINUX" "ct-lt-2506-nixos"];
  sway-wrapped-hw = pkgs.writeScript "sway-wrapped-hw" ''
    #!${pkgs.runtimeShell}
    export WLR_NO_HARDWARE_CURSORS=1
    ${lib.optionalString needsNoAtomicDrm ''
      export WLR_DRM_NO_ATOMIC=1
      # The DisplayLink dock can attach its evdi outputs while sway is still
      # starting (greeter or session), and the resulting hotplug races
      # sway's view/output mapping into a fatal "cannot map mapped view"
      # assertion. Restrict wlroots to the PCI GPU(s) actually driving a
      # display so evdi hotplug can't reach sway's DRM backend at all. A
      # PCI GPU with no connected output (e.g. an offload-only/compute-only
      # card) must be excluded too: once WLR_DRM_DEVICES is set explicitly,
      # wlroots aborts if any listed device fails to initialise, instead of
      # skipping it like it would during auto-probing.
      #
      # WLR_DRM_DEVICES is itself colon-separated, so the by-path symlink
      # (e.g. pci-0000:00:02.0-card) can't be used verbatim: its PCI
      # address colons get parsed as list separators, splitting one device
      # into several bogus paths and leaving wlroots with 0 GPUs. Resolve
      # to the colon-free /dev/dri/cardN target before joining.
      drm_devices=""
      for dev in /dev/dri/by-path/pci-*-card; do
        [ -e "$dev" ] || continue
        card="$(basename "$(readlink -f "$dev")")"
        connected=""
        for status in /sys/class/drm/"$card"-*/status; do
          [ -e "$status" ] || continue
          if [ "$(cat "$status")" = "connected" ]; then
            connected=1
            break
          fi
        done
        [ -n "$connected" ] || continue
        drm_devices="''${drm_devices:+$drm_devices:}/dev/dri/$card"
      done
      [ -n "$drm_devices" ] && export WLR_DRM_DEVICES="$drm_devices"
    ''}
    exec ${getExe pkgs.sway} --unsupported-gpu "$@"
  '';
in {
  config = mkIf enabled {
    environment.etc."greetd/kanshi-config" = {
      source = "${config.users.users."dzrodriguez".home}/.config/kanshi/config";
      uid = 0;
      gid = 0;
      mode = "777";
    };

    services = {
      xserver = {
        enable = true;
        displayManager = {
          startx.enable = true;
        };
        xkb.layout = "us";
      };
      displayManager = {
        sessionPackages = let
          swayUnsupportedSession =
            (pkgs.makeDesktopItem {
              name = "sway-unsupported";
              desktopName = "Sway (Unsupported GPU)";
              comment = "Start Sway with --unsupported-gpu";
              exec = sway-wrapped-hw;
              type = "Application";
              destination = "/share/wayland-sessions";
            }).overrideAttrs (_old: {
              passthru.providedSessions = ["sway-unsupported"];
            });
        in
          lib.optional (config.nixfigs.graphical.windowManagers.selectedWindowManager == "sway") swayUnsupportedSession;
      };
      desktopManager = {
        plasma6.enable = true;
      };
      libinput.enable = true;
      greetd = {
        enable = true;
        settings = {
          default_session = let
            swayConfig = pkgs.writeText "greetd-sway-config" ''
              exec "${getExe pkgs.kanshi} -c /etc/greetd/kanshi-config"
              exec "dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP; ${getExe pkgs.regreet}; swaymsg exit"
              bindsym Mod4+shift+e exec swaynag \
              -t warning \
              -m 'What do you want to do?' \
              -b 'Poweroff' 'systemctl poweroff' \
              -b 'Reboot' 'systemctl reboot'
            '';
          in {
            command = "${sway-wrapped-hw} --config ${swayConfig}";
            user = "greeter";
          };
        };
      };
    };
    programs.regreet = {
      enable = true;
      settings = {
        commands = {
          reboot = ["loginctl" "reboot"];
          poweroff = ["loginctl" "poweroff"];
        };
        GTK.application_prefer_dark_theme = true;
        appearance.greeting_msg = "Welcome to ${config.networking.hostName}! Please authenticate yourself.";
      };
    };
    programs.ssh.askPassword = pkgs.lib.mkForce "${pkgs.kdePackages.ksshaskpass.out}/bin/ksshaskpass";
    environment.sessionVariables =
      {NIXOS_OZONE_WL = "1";}
      // lib.optionalAttrs needsNoAtomicDrm {KWIN_DRM_NO_AMS = "1";};
  };
}
