{ config, pkgs, lib, ... }: {
  imports = [
      ./arm-board.nix
  ];

  environment.systemPackages = with pkgs; [
    #trinity
    #i2c-tools
    #mesa
    #mesa_drivers
    #kmscon
    #kmscube
    #glmark2
    #westonLite
    #ffmpeg
    #libvpx
  ];

  nix.maxJobs = 4;
  nix.requireSignedBinaryCaches = false;
  nix.useSandbox = true;

  networking.hostName = "jetson";
  networking.hostId = "71d65fa9";

  hardware.enableAllFirmware = true; # XXX needed for Ethernet
  hardware.opengl.enable = false;

  boot.kernelParams = ["console=ttyS0,115200n8 cma=8M"];
  boot.blacklistedKernelModules = ["tegra_devfreq"];
  #boot.kernelPackages = pkgs.linuxPackages_testing;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  #boot.kernelPackages = pkgs.linuxPackages_4_9;
  #boot.kernelPackages = pkgs.linuxPackages_dezgeg;

  fileSystems."/" = {
    device = "/dev/mmcblk0p1";
    fsType = "ext4";
  };
  swapDevices = [ { device = "/dev/mmcblk0p2"; } ];
}
