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

  nix.requireSignedBinaryCaches = false;
  nix.package = pkgs.nixDezgeg;

  networking.hostName = "jetson";
  networking.hostId = "71d65fa9";

  hardware.opengl.enable = true;

  boot.blacklistedKernelModules = ["tegra_devfreq"];
  #boot.kernelPackages = pkgs.linuxPackages_testing;
  boot.kernelPackages = pkgs.linuxPackages_dezgeg;

  fileSystems."/" = {
    device = "/dev/mmcblk0p1";
    fsType = "ext4";
  };
  swapDevices = [ { device = "/dev/mmcblk0p2"; } ];
}
