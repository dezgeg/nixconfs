{ config, pkgs, lib, ... }: {
  imports = [
      ./arm-board.nix
  ];

  environment.systemPackages = with pkgs; [
  ];

  networking.hostName = "raspi";
  networking.hostId = "8f076ab4";

  boot.kernelParams = ["smsc95xx.macaddr=b8:27:eb:63:84:ca"];
  boot.kernelPackages = pkgs.linuxPackages_rpi;

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
