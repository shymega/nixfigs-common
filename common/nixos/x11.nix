# SPDX-FileCopyrightText: 2024 Dom Rodriguez <shymega@shymega.org.uk
#
# SPDX-License-Identifier: GPL-3.0-only
#
{
  pkgs,
  lib,
  libx,
  config,
  inputs,
  ...
}:
with lib; let
  inherit (libx.roleUtils) checkRoles;
  enabled = checkRoles ["workstation"] config.nixfigs.meta.rolesEnabled;
  sway-wrapped-hw = pkgs.writeShellScript "sway-wrapped-hw" ''
    #!/bin/sh
    export WLR_NO_HARDWARE_CURSORS=1
    exec ${getExe pkgs.sway} --unsupported-gpu "$@"
  '';
  hyprland = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland.overrideAttrs (_oldAttrs: {
    patches = [
      (pkgs.fetchpatch {
        url = "https://gist.githubusercontent.com/shymega/6da41e750cf9da0042afd4ac82916874/raw/0a44703af7592bbdb835759419ddf25188ccac4b/0001-hyprpm-Apply-patch-for-glaze.patch";
        hash = "sha256-SnoHXUx6AvhbzvKVck647lDawMOfx865/t92vYkwZ+I=";
      })
    ];
  });
in {
  config = mkIf enabled {
    environment.etc."greetd/kanshi-config" = {
      source = "${config.users.users."dzrodriguez".home}/.config/kanshi/config";
      uid = 0;
      gid = 0;
      mode = "777";
    };

    services = {
      displayManager.defaultSession = "sway";
      xserver = {
        enable = true;
        displayManager = {
          startx.enable = true;
        };
        xkb.layout = "us";
      };
      desktopManager = {
        plasma6.enable = true;
      };
      libinput.enable = true;
      greetd = {
        enable = true;
        settings = {
          default_session = let
            hyprConfig = pkgs.writeText "greetd-hyprland-config" ''
              exec-once=${getExe pkgs.kanshi} -c /etc/greetd/kanshi-config
              exec-once=${getExe pkgs.regreet}; hyprctl dispatch exit
              debug {
                disable_scale_checks = true
              }
              misc {
                disable_hyprland_logo = true
                disable_splash_rendering = true
              }
              ecosystem {
                no_update_news = true
                no_donation_nag = true
              }
              input {
                touchdevice {
                  enabled=true
                }
                touchpad {
                  natural_scroll=false
                }
                follow_mouse=1
                sensitivity=0.500000
              }
              monitor=WAYLAND-1,disabled
              env = AQ_NO_MODIFIERS,1
              env = GDK_BACKEND,wayland
              env = GDK_DEBUG,no-portals
              env = GDK_SCALE,2
              env = GTK_USE_PORTAL,0
              env = MOZ_ENABLE_WAYLAND,1
              env = QT_AUTO_SCREEN_SCALE_FACTOR,1
              env = QT_ENABLE_HIGHDPI_SCALING,1
              env = QT_QPA_PLATFORM,wayland;xcb
              env = QT_WAYLAND_DISABLE_WINDOWDECORATION,1
              env = SDL_VIDEODRIVER,wayland
              env = XDG_SESSION_TYPE,wayland
              env = _JAVA_AWT_WM_NONREPARENTING,1
              cursor {
                no_hardware_cursors = 1
              }
            '';
          in {
            command = "${getExe hyprland} --config ${hyprConfig}";
            user = "greeter";
          };
        };
      };
    };
    environment.etc."greetd/environments".text = ''
      ${getExe hyprland}
      ${sway-wrapped-hw}
      ${getExe pkgs.dwl}
      ${pkgs.kdePackages.plasma-workspace}/bin/startplasma-wayland
      ${pkgs.kdePackages.plasma-workspace}/bin/startplasma-X11
    '';
    programs.regreet = {
      enable = true;
      settings = {
        commands = {
          reboot = ["loginctl" "reboot"];
          poweroff = ["loginctl" "poweroff"];
        };
        GTK.application_prefer_dark_theme = true;
        appearance.greeting_msg = "Welcome back to ${config.networking.hostName}!";
      };
    };
    programs.ssh.askPassword = pkgs.lib.mkForce "${pkgs.kdePackages.ksshaskpass.out}/bin/ksshaskpass";
    environment.sessionVariables.NIXOS_OZONE_WL = "1";
  };
}
