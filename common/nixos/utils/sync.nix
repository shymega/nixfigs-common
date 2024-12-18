# SPDX-FileCopyrightText: 2024 Dom Rodriguez <shymega@shymega.org.uk
#
# SPDX-License-Identifier: GPL-3.0-only
{pkgs, ...}: {
  environment.systemPackages = [
    (pkgs.writeScriptBin "clean-syncthing" ''
      #! ${pkgs.stdenv.shell}
      set -eu

      ${pkgs.lib.getExe' pkgs.coreutils "find"} /home/dzr/{Documents,Multimedia,projects} -type f -iname "*sync-conflict*" -print -delete
      ${pkgs.lib.getExe' pkgs.coreutils "find"} /home/dzr/{Documents,Multimedia,projects} -type f -iname ".#*" -print -delete
      ${pkgs.lib.getExe' pkgs.coreutils "find"} /home/dzr/{Documents,Multimedia,projects} -type f -iname "*~*" -print -delete
      ${pkgs.lib.getExe' pkgs.coreutils "find"} /home/dzr/{Documents,Multimedia,projects} -type f -iname ".syncthing*" -print -delete
    '')
  ];
}
