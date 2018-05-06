{ config, pkgs, lib, ... }: {
  imports = [
      ./arm-board.nix
  ];

  environment.systemPackages = with pkgs; [
  ];

  networking.hostName = "raspi";
  networking.hostId = "8f076ab4";

  boot.loader.grub.enable = false;
  boot.loader.raspberryPi.enable = true;
  boot.loader.raspberryPi.version = 1;
  boot.loader.raspberryPi.uboot.enable = true;
  boot.loader.raspberryPi.firmwareConfig = ''
    arm_freq=950
    sdram_freq=500
    core_freq=300
    gpu_freq=300
    over_voltage=6
    gpu_mem=16
  '';

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
  swapDevices = [ { device = "/swap"; } ];
}
