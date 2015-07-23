{ config, pkgs, lib, ... }: {
  imports = [
      ./arm-board.nix
  ];

  environment.systemPackages = with pkgs; [
  ];

  networking.hostName = "pcduino";
  networking.hostId = "b4d1498d";

  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-label/NIXOS_BOOT";
      fsType = "vfat";
    };
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };
  };
}
