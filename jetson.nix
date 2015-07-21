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

  networking.hostName = "jetson";
  networking.hostId = "71d65fa9";

  hardware.opengl.enable = true;

  fileSystems."/" = {
    device = "/dev/mmcblk0p1";
    fsType = "ext4";
  };
  swapDevices = [ { device = "/dev/mmcblk0p2"; } ];
}
