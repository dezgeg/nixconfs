{ config, pkgs, lib, ... }: {

  imports = [
      ./common.nix
      ./passwords.nix
  ];

  boot.initrd.availableKernelModules = [ "ahci" ];
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.kernelPackages = pkgs.linuxPackages_latest;

  fileSystems."/" = {
    device = "/dev/disk/by-label/THINKPAD_ROOT";
    fsType = "f2fs";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/THINKPAD_BOOT";
    fsType = "ext4";
  };

  swapDevices = [
    { device = "/dev/disk/by-label/NIXOS_SWAP"; }
  ];

  hardware.enableRedistributableFirmware = true;

  environment.systemPackages = with pkgs; [
    picocom
  ];

  services.logind.extraConfig = ''
    HandleLidSwitch=ignore
  '';

  #services.ddclient = {
  #  enable = true;
  #  protocol = "namecheap";
  #  domain = "kbuilder";
  #  username = "dezgeg.me";
  #  server = "dynamicdns.park-your-domain.com";
  #  # password comes from ./passwords.nix
  #};

  nix.maxJobs = 4;

}
