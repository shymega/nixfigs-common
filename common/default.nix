# SPDX-FileCopyrightText: 2023-2026 Dom 'shymega' Rodriguez <shymega@shymega.org.uk>
#
# SPDX-License-Identifier: Apache-2.0
{
  inputs,
  lib,
  pkgs,
  hostType ? "nixos",
  hostname ? "UNKNOWN-HOST",
  ...
}: {
  imports =
    [
      (import ./core {
        inherit
          inputs
          lib
          pkgs
          hostname
          ;
      })
    ]
    ++ (
      if hostType == "nixos"
      then [
        (import ./nixos {
          inherit
            inputs
            lib
            pkgs
            hostname
            ;
        })
      ]
      else if hostType == "darwin"
      then [
        (import ./darwin {
          inherit
            inputs
            lib
            pkgs
            hostname
            ;
        })
      ]
      else []
    );
}
