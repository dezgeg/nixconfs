{ config, pkgs, ... }: {

  imports = [
      ./hardware-configuration.nix
      ./common.nix
      ./passwords.nix
    ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.kernelParams = ["usbcore.nousb=1"];

  networking.hostName = "xen";
  networking.hostId = "a99b9c2b";
  networking.wireless.enable = true;

  virtualisation.xen.enable = true;
  virtualisation.xen.domain0MemorySize = 2048;

  services.ddclient = {
    enable = true;
    protocol = "namecheap";
    domain = "xen";
    username = "dezgeg.me";
    server = "dynamicdns.park-your-domain.com";
    # password comes from ./passwords.nix
  };
}
