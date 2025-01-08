# SPDX-FileCopyrightText: 2024 Dom Rodriguez <shymega@shymega.org.uk
#
# SPDX-License-Identifier: GPL-3.0-only
#
{
  pkgs,
  lib,
  ...
}: let
  kanshiConfig = pkgs.writeText "kanshi-config" ''${builtins.readFile ./config/kanshi/config}'';
  swayConfig = pkgs.writeText "greetd-sway-config" ''
    # `-l` activates layer-shell mode. Notice that `swaymsg exit` will run after gtkgreet.
    exec "${pkgs.lib.getExe pkgs.kanshi} -c ${kanshiConfig}"
    exec "dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP; ${pkgs.lib.getExe pkgs.greetd.gtkgreet} -l; swaymsg exit"
    bindsym Mod4+shift+e exec swaynag \
      -t warning \
      -m 'What do you want to do?' \
      -b 'Poweroff' 'systemctl poweroff' \
      -b 'Reboot' 'systemctl reboot'
  '';
in {
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
          command = "${pkgs.lib.getExe pkgs.sway} --config ${swayConfig}";
        };
        inital_session.user = "dzrodriguez";
      };
    };
  };
  environment.etc."greetd/environments".text = let
    sway-wrapped-hw = pkgs.writeShellScript "sway-wrapped-hw" ''
      #!/bin/sh
      export WLR_NO_HARDWARE_CURSORS=1
      exec ${pkgs.lib.getExe pkgs.sway}
    '';
  in ''
    ${sway-wrapped-hw}
    ${pkgs.lib.getExe pkgs.dwl}
    startplasma-wayland
    startplasma-x11
    zsh
  '';
  programs.ssh.askPassword = lib.mkForce "${pkgs.ksshaskpass}/bin/ksshaskpass";
}
