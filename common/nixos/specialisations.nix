# SPDX-FileCopyrightText: 2023-2026 Dom 'shymega' Rodriguez <shymega@shymega.org.uk>
#
# SPDX-License-Identifier: Apache-2.0
#
{
  lib,
  pkgs,
  config,
  ...
}: let
  isTargetHost =
    config.networking.hostName
    == "HEIMDALL-LINUX"
    || config.networking.hostName == "FREYR-LINUX"
    || config.networking.hostName == "MJOLNIR-LINUX";

  hasNvidia = lib.elem "nvidia" config.services.xserver.videoDrivers;

  ltsKernelConfig = {
    boot.kernelPackages = lib.mkForce pkgs.linuxPackages_6_18;
    # `pkgs.zfs` is the default `boot.zfs.package` value; the NixOS zfs
    # module auto-selects the matching kernel module for whatever
    # `kernelPackages` is active via `cfgZfs.modulePackage`. Do not point
    # this at `config.boot.kernelPackages.${pkgs.zfs.kernelModuleAttribute}`
    # directly -- nixpkgs builds that attribute with `configFile = "kernel"`
    # (kernel module only, no userspace tools, no `lib/udev`), which breaks
    # activation: "failed to get symlink metadata for .../lib/udev".
    boot.zfs.package = lib.mkForce pkgs.zfs;
  };

  swayConfig = {
    nixfigs.graphical.windowManagers.selectedWindowManager = lib.mkForce "sway";
  };

  nvidiaOffloadConfig = {
    hardware.nvidia.prime = {
      sync.enable = lib.mkForce false;
      offload = {
        enable = lib.mkForce true;
        enableOffloadCmd = lib.mkForce true;
      };
    };
  };

  nvidiaSyncConfig = {
    hardware.nvidia.prime = {
      sync.enable = lib.mkForce true;
      offload = {
        enable = lib.mkForce false;
        enableOffloadCmd = lib.mkForce false;
      };
    };
  };

  noDisplayLinkConfig = {
    services.xserver.videoDrivers =
      lib.mkForce (lib.remove "displaylink" config.services.xserver.videoDrivers);
  };

  atomicDrmConfig = {
    nixfigs.graphical.needsNoAtomicDrm = lib.mkForce false;
  };
in {
  config = lib.mkIf isTargetHost {
    specialisation =
      {
        lts = {
          inheritParentConfig = true;
          configuration = ltsKernelConfig;
        };

        sway = {
          inheritParentConfig = true;
          configuration = swayConfig;
        };

        lts-sway = {
          inheritParentConfig = true;
          configuration = ltsKernelConfig // swayConfig;
        };

        atomic-drm = {
          inheritParentConfig = true;
          configuration = atomicDrmConfig;
        };

        lts-no-displaylink = {
          inheritParentConfig = true;
          configuration = ltsKernelConfig // noDisplayLinkConfig;
        };

        lts-sway-no-displaylink = {
          inheritParentConfig = true;
          configuration = ltsKernelConfig // swayConfig // noDisplayLinkConfig;
        };
      }
      // lib.optionalAttrs hasNvidia {
        nvidia-offload = {
          inheritParentConfig = true;
          configuration = nvidiaOffloadConfig;
        };

        lts-nvidia-offload = {
          inheritParentConfig = true;
          configuration = ltsKernelConfig // nvidiaOffloadConfig;
        };

        lts-sway-nvidia-offload = {
          inheritParentConfig = true;
          configuration = ltsKernelConfig // swayConfig // nvidiaOffloadConfig;
        };

        nvidia-offload-no-displaylink = {
          inheritParentConfig = true;
          configuration = nvidiaOffloadConfig // noDisplayLinkConfig;
        };

        lts-nvidia-offload-no-displaylink = {
          inheritParentConfig = true;
          configuration = ltsKernelConfig // nvidiaOffloadConfig // noDisplayLinkConfig;
        };

        lts-sway-nvidia-offload-no-displaylink = {
          inheritParentConfig = true;
          configuration = ltsKernelConfig // swayConfig // nvidiaOffloadConfig // noDisplayLinkConfig;
        };

        nvidia-sync = {
          inheritParentConfig = true;
          configuration = nvidiaSyncConfig;
        };

        lts-nvidia-sync = {
          inheritParentConfig = true;
          configuration = ltsKernelConfig // nvidiaSyncConfig;
        };

        lts-sway-nvidia-sync = {
          inheritParentConfig = true;
          configuration = ltsKernelConfig // swayConfig // nvidiaSyncConfig;
        };

        nvidia-sync-no-displaylink = {
          inheritParentConfig = true;
          configuration = nvidiaSyncConfig // noDisplayLinkConfig;
        };

        lts-nvidia-sync-no-displaylink = {
          inheritParentConfig = true;
          configuration = ltsKernelConfig // nvidiaSyncConfig // noDisplayLinkConfig;
        };

        lts-sway-nvidia-sync-no-displaylink = {
          inheritParentConfig = true;
          configuration = ltsKernelConfig // swayConfig // nvidiaSyncConfig // noDisplayLinkConfig;
        };
      };
  };
}
