# SPDX-FileCopyrightText: 2023-2026 Dom 'shymega' Rodriguez <shymega@shymega.org.uk>
#
# SPDX-License-Identifier: Apache-2.0
#
{
  pkgs,
  config,
  lib,
  ...
}: {
  programs.sway = {
    enable = config.nixfigs.graphical.windowManagers.selectedWindowManager == "sway";
    package = pkgs.sway;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [
      swayidle
      swaylock
      wofi
    ];
    extraSessionCommands = ''
      export MOZ_ENABLE_WAYLAND=1
      export QT_QPA_PLATFORM=wayland
      export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
      export SDL_VIDEODRIVER=wayland
      export XDG_CURRENT_DESKTOP=sway
      export XDG_SESSION_TYPE=wayland
      export _JAVA_AWT_WM_NONREPARENTING=1
      ${
        # evdi (DisplayLink) doesn't reliably signal atomic commit completion
        # behind the PRIME-sync nvidia/intel hybrid pipeline on these hosts,
        # which times out the flip and leaves the panel on "No Signal".
        lib.optionalString (builtins.elem config.networking.hostName ["MJOLNIR-LINUX" "ct-lt-2506-nixos"]) ''
          export WLR_DRM_NO_ATOMIC=1
        ''
      }
    '';
  };
}
