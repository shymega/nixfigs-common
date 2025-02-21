# SPDX-FileCopyrightText: 2024 Dom Rodriguez <shymega@shymega.org.uk
#
# SPDX-License-Identifier: GPL-3.0-only
#
{
  pkgs,
  lib,
  libx,
  hostRoles,
  config,
  ...
}:
with lib; let
  swayConfig = pkgs.writeText "greetd-sway-config" ''
    # `-l` activates layer-shell mode. Notice that `swaymsg exit` will run after gtkgreet.
    exec "${getExe pkgs.kanshi} -c /etc/greetd/kanshi-config"
    exec "dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP; ${getExe pkgs.greetd.gtkgreet} -l; swaymsg exit"
    bindsym Mod4+shift+e exec swaynag \
      -t warning \
      -m 'What do you want to do?' \
      -b 'Poweroff' 'systemctl poweroff' \
      -b 'Reboot' 'systemctl reboot'
  '';
  enabled = libx.roleUtils.checkRoles ["workstation" "work"] hostRoles;
in {
  config = mkIf enabled {
    environment.etc."greetd/kanshi-config".source = "${config.users.users."dzrodriguez".home}/.config/kanshi/config";

    services = {
      displayManager.defaultSession = "sway";
      xserver = {
        enable = true;
        displayManager = {
          startx.enable = true;
          gdm = {
            enable = false;
            autoSuspend = false;
          };
        };
        desktopManager.gnome.enable = true;
        xkb.layout = "us";
      };

      desktopManager = {
        plasma6.enable = true;
      };
      libinput.enable = true;
      greetd = {
        enable = true;
        settings = {
          default_session = {
            command = "${getExe pkgs.sway} --config ${swayConfig}";
          };
          inital_session.user = "dzrodriguez";
        };
      };
    };
    environment.etc."greetd/environments".text = let
      sway-wrapped-hw = pkgs.writeShellScript "sway-wrapped-hw" ''
        #!/bin/sh
        export WLR_NO_HARDWARE_CURSORS=1
        exec ${getExe pkgs.sway} --unsupported-gpu
      '';
    in ''
      ${sway-wrapped-hw}
      ${getExe pkgs.dwl}
      startplasma-wayland
      startplasma-x11
      zsh
    '';
    programs.ssh.askPassword = mkForce "${getExe pkgs.ksshaskpass}/bin/ksshaskpass";
  };
}
