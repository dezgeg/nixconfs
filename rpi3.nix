{ config, pkgs, lib, ... }: {
  imports = [
      ./arm-board.nix
  ];

  environment.systemPackages = with pkgs; [
    kmscube
    westonLite
    glmark2
    amoeba
  ];

  networking.hostName = "rpi3";
  networking.hostId = "8f076ab3";

  nix.maxJobs = 4;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = ["console=tty0" "cma=128M" ];

  hardware.opengl.enable = true;
  services.xserver = {
    enable = true;
    autorun = true;
    displayManager.auto = {
      enable = true;
      user = "tmtynkky";
    };
    desktopManager.xterm.enable = false;
    windowManager.i3.enable = true;
    windowManager.default = "i3";
    videoDrivers = [ "modesetting" ];
  };

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
