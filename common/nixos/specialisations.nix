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

  nvidiaOffloadConfig = {
    hardware.nvidia.prime = {
      sync.enable = lib.mkForce false;
      offload = {
        enable = lib.mkForce true;
        enableOffloadCmd = lib.mkForce true;
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
  options.nixfigs.meta.specialisation = lib.mkOption {
    type = lib.types.str;
    default = let
      inherit (config.boot.loader.grub) configurationName;
    in
      if configurationName == ""
      then "default"
      else configurationName;
  };

  config = lib.mkIf isTargetHost {
    specialisation = lib.mapAttrs (name: spec:
      spec
      // {
        configuration =
          spec.configuration
          // {
            nixfigs.meta.specialisation = name;
          };
      }) (
      {
        lts = {
          inheritParentConfig = true;
          configuration = ltsKernelConfig;
        };

        atomic-drm = {
          inheritParentConfig = true;
          configuration = atomicDrmConfig;
        };

        lts-atomic-drm = {
          inheritParentConfig = true;
          configuration = ltsKernelConfig // atomicDrmConfig;
        };

        no-displaylink = {
          inheritParentConfig = true;
          configuration = noDisplayLinkConfig;
        };

        lts-no-displaylink = {
          inheritParentConfig = true;
          configuration = ltsKernelConfig // noDisplayLinkConfig;
        };
      }
      // lib.optionalAttrs (isTargetHost && hasNvidia) {
        nvidia-offload = {
          inheritParentConfig = true;
          configuration = nvidiaOffloadConfig;
        };

        lts-nvidia-offload = {
          inheritParentConfig = true;
          configuration = ltsKernelConfig // nvidiaOffloadConfig;
        };

        nvidia-offload-atomic-drm = {
          inheritParentConfig = true;
          configuration = nvidiaOffloadConfig // atomicDrmConfig;
        };

        lts-nvidia-offload-atomic-drm = {
          inheritParentConfig = true;
          configuration = ltsKernelConfig // nvidiaOffloadConfig // atomicDrmConfig;
        };

        nvidia-offload-no-displaylink = {
          inheritParentConfig = true;
          configuration = nvidiaOffloadConfig // noDisplayLinkConfig;
        };

        lts-nvidia-offload-no-displaylink = {
          inheritParentConfig = true;
          configuration = ltsKernelConfig // nvidiaOffloadConfig // noDisplayLinkConfig;
        };
      }
    );
  };
}
