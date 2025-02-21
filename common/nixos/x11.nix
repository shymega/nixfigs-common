# SPDX-FileCopyrightText: 2024 Dom Rodriguez <shymega@shymega.org.uk
#
# SPDX-License-Identifier: GPL-3.0-only
#
{pkgs, ...}: let
  kanshiConfig = pkgs.writeText "config.kanshi" ''
    profile desk_home_mini_pc {
      output "LG Electronics LG Ultra HD 0x0009B7B4" enable mode 3840x2160 position 0,0 scale 1.50
      output "BNQ BENQ E2220HD SBA04454019" enable mode 1920x1080 position 2634,0
    }

    profile default_gpdwm2 {
      output "Japan Display Inc. GPD1001H 0x00000001" enable mode 2560x1600 scale 1.75 position 0,0
    }

    profile portable_monitor_gpdwm2 {
      output "Japan Display Inc. GPD1001H 0x00000001" enable mode 2560x1600 position 2803,795 scale 1.50
      output "DO NOT USE - RTK FlipGo-A2 demoset-1" enable mode 2256x1504 position 5363,1798 scale 1.50
      output "DO NOT USE - RTK FlipGo-A1 demoset-1" enable mode 2256x1504 position 5363,795 scale 1.50
    }

    profile home_office_gpdwm2 {
      output "Japan Display Inc. GPD1001H 0x00000001" disable
      output "LG Electronics LG Ultra HD 0x0009B7B4" enable mode 3840x2160 position 0,0 scale 1.50
      output "BNQ BENQ E2220HD SBA04454019" enable mode 1920x1080 position 2634,0 scale 1.00
      output "DO NOT USE - RTK FlipGo-A2 demoset-1" enable mode 2256x1504 position 4554,1080 scale 1.50
      output "DO NOT USE - RTK FlipGo-A1 demoset-1" enable mode 2256x1504 position 4554,0 scale 1.50
    }

    profile default_thinkpad_x270 {
      output "Unknown 0x226D 0x00000000" enable mode 1920x1080 position 0,0
    }

    profile desk_home_thinkpad_x270 {
      output "Unknown 0x226D 0x00000000" disable
      output "LG Electronics LG Ultra HD 0x0000BFB4" enable mode 3840x2160 position 0,0 scale 1.50
      output "BNQ BENQ E2220HD SBA04454019" enable mode 1920x1080 position 2194,0
    }

    profile default_codethink {
      output "California Institute of Technology 0x1404 Unknown" enable mode 1920x1200 scale 1.00 position 0,0
    }

    profile home_office_codethink {
      output "California Institute of Technology 0x1404 Unknown" disable
      output "LG Electronics LG Ultra HD 0x0009B7B4" enable mode 3840x2160 position 0,0 scale 1.50
      output "BNQ BENQ E2220HD SBA04454019" enable mode 1920x1080 position 2634,0 scale 1.00
    }

    profile mirror_codethink_hdmi {
      output "California Institute of Technology 0x1404 Unknown" enable mode 1920x1200 scale 1.00 position 0,0
      output HDMI-A-1 enable mode 1920x1080 position 1920,0
      exec wl-present mirror eDP-1 --fullscreen-output HDMI-A-1 --fullscreen
    }

    profile mirror_gpd_wm2_hdmi {
      output "Japan Display Inc. GPD1001H 0x00000001" enable mode 2634x1600 scale 1.50 position 0,0
      output HDMI-A-1 enable mode 1920x1080 position 1920,0
      exec wl-present mirror eDP-1 --fullscreen-output HDMI-A-1 --fullscreen
    }

    profile mirror_thinkpad_x270_hdmi {
      output "Unknown 0x226D 0x00000000" enable mode 1920x1080 position 0,0
      output HDMI-A-1 enable mode 1920x1080 position 1920,0
      exec wl-present mirror eDP-1 --fullscreen-output HDMI-A-1 --fullscreen
    }
  '';
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
  environment.etc."greetd/environments".text = ''
    ${pkgs.lib.getExe pkgs.sway}
    ${pkgs.lib.getExe pkgs.dwl}
    plasmax11
    plasma
    zsh
  '';
}
