# SPDX-FileCopyrightText: 2023-2026 Dom 'shymega' Rodriguez <shymega@shymega.org.uk>
#
# SPDX-License-Identifier: Apache-2.0
#
{
  lib,
  libx,
  ...
}: let
  inherit (libx) isDarwin isNixOS isLinux;
in {
  programs = {
    tmux = {
      enable = true;
      shortcut = lib.mkDefault "b";
      aggressiveResize = (isNixOS || isLinux) && !isDarwin;
      baseIndex = 0;
      keyMode = "emacs";
      newSession = false;
      terminal = "tmux-256color";
    };
  };
}
