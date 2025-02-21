# SPDX-FileCopyrightText: 2024 Dom Rodriguez <shymega@shymega.org.uk
#
# SPDX-License-Identifier: GPL-3.0-only

#

{ config, lib, pkgs, ... }:
let
  kanshiConfig = pkgs.writeText "config.kanshi" ''
    profile desk_home_mini_pc {
        output "LG Electronics LG Ultra HD 0x0009B7B4" enable mode 3840x2160 position 0,0 scale 1.55
        output "BNQ BENQ E2220HD SBA04454019" enable mode 1920x1080 position 2194,0
    }

    profile default_gpdwm2 {
      output "Japan Display Inc. GPD1001H 0x00000001" enable mode 2560x1600 scale 1.50 position 0,0
    }

    profile home_office_gpdwm2 {
      output "Japan Display Inc. GPD1001H 0x00000001" disable
      output "LG Electronics LG Ultra HD 0x0009B7B4" enable mode 3840x2160 position 0,0 scale 1.55
      output "BNQ BENQ E2220HD SBA04454019" enable mode 1920x1080 position 2482,0 scale 1.00
    }

    profile default_thinkpad_x270 {
        output "Unknown 0x226D 0x00000000" enable mode 1920x1080 position 0,0
    }

    profile desk_home_thinkpad_x270 {
        output "Unknown 0x226D 0x00000000" disable	
        output "LG Electronics LG Ultra HD 0x0000BFB4" enable mode 3840x2160 position 0,0 scale 1.55
        output "BNQ BENQ E2220HD SBA04454019" enable mode 1920x1080 position 2194,0
    }

    profile default_codethink {
      output "California Institute of Technology 0x1404 Unknown" enable mode 1920x1200 scale 1.00 position 0,0
    }

    profile home_office_codethink {
      output "California Institute of Technology 0x1404 Unknown" disable
      output "LG Electronics LG Ultra HD 0x0009B7B4" enable mode 3840x2160 position 0,0 scale 1.55
      output "BNQ BENQ E2220HD SBA04454019" enable mode 1920x1080 position 2476,0 scale 1.00
    }

    profile mirror_codethink_hdmi {
        output "California Institute of Technology 0x1404 Unknown" enable mode 1920x1200 scale 1.00 position 0,0
        output HDMI-A-1 enable mode 1920x1080 position 1920,0
        exec wl-present mirror eDP-1 --fullscreen-output HDMI-A-1 --fullscreen
    }

    profile mirror_gpd_wm2_hdmi {
      output "Japan Display Inc. GPD1001H 0x00000001" enable mode 2560x1600 scale 1.50 position 0,0
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
        exec "dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP; \
    	${pkgs.lib.getExe pkgs.greetd.gtkgreet} -l; swaymsg exit"
        bindsym Mod4+shift+e exec swaynag \
          -t warning \
          -m 'What do you want to do?' \
          -b 'Poweroff' 'systemctl poweroff' \
          -b 'Reboot' 'systemctl reboot'
  '';
in
{
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

      desktopManager = {
        plasma5.enable = true;
        cinnamon.enable = true;
        gnome.enable = false;
      };
      xkb.layout = "us";
    };
    libinput.enable = true;
    greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.lib.getExe' pkgs.sway "sway"} --config ${swayConfig}";
        };
      };
    };
  };

  environment.etc."greetd/environments".text = ''
    ${pkgs.lib.getExe pkgs.zsh} --login -c "sway"
    ${pkgs.lib.getExe pkgs.zsh} --login -c "dwl"
    ${pkgs.lib.getExe pkgs.zsh} --login -c "startplasma-x11"
    ${pkgs.lib.getExe pkgs.zsh} --login -c "startplasma-wayland"
    ${pkgs.lib.getExe pkgs.zsh} --login
  '';

  environment.sessionVariables.NIX_GSETTINGS_OVERRIDES_DIR =
    let
      cfg = config.services.xserver.desktopManager.gnome;
      nixos-background-light = pkgs.nixos-artwork.wallpapers.simple-blue;
      nixos-background-dark = pkgs.nixos-artwork.wallpapers.simple-dark-gray;
      flashbackEnabled = cfg.flashback.enableMetacity || lib.length cfg.flashback.customSessions > 0;
      nixos-gsettings-desktop-schemas = pkgs.gnome.nixos-gsettings-overrides.override {
        inherit (cfg) extraGSettingsOverrides extraGSettingsOverridePackages favoriteAppsOverride;
        inherit flashbackEnabled nixos-background-dark nixos-background-light;
      };
    in
    lib.mkForce (pkgs.glib.getSchemaPath nixos-gsettings-desktop-schemas);

  programs.ssh.askPassword = pkgs.lib.mkForce "${pkgs.lib.getExe' pkgs.gnome.seahorse "ssh-askpass"}";
}
