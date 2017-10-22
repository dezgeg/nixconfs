{ config, pkgs, lib, ... }: {

  imports = [
      ./common.nix
      ./passwords.nix
  ];

  boot.initrd.availableKernelModules = [ "ahci" ];
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;
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
    { device = "/dev/disk/by-label/THINKPAD_SWAP"; }
  ];

  hardware.enableRedistributableFirmware = true;

  environment.systemPackages = with pkgs; [
    acpi
    claws-mail
    gnumake
    gnuplot_qt
    google-chrome
    mpv
    networkmanagerapplet
    pavucontrol
    picocom
    python2
    python3
    redshift
    ruby
    rxvt_unicode
    scrot
    sshfs
    steam
    xclip
    xorg.xbacklight
  ];

  networking.hostName = "thinkpad";
  networking.hostId = "119933b3";
  networking.networkmanager.enable = true;

  services.logind.extraConfig = ''
    HandleLidSwitch=ignore
  '';

  services.ddclient = {
    enable = true;
    protocol = "namecheap";
    domain = "@";
    username = "dezgeg.me";
    server = "dynamicdns.park-your-domain.com";
    # password comes from ./passwords.nix
  };

  nix.maxJobs = 4;

  services.xserver = {
    enable = true;
    autorun = true;

    # displayManager.lightdm.enable = true;
    displayManager.auto = {
      enable = true;
      user = "tmtynkky";
    };

    desktopManager.xterm.enable = false;
    windowManager.i3.enable = true;
    windowManager.default = "i3";

    libinput.enable = true; # for touchpad
  };
  hardware.pulseaudio.enable = true;
  hardware.opengl.enable = true;
  hardware.opengl.driSupport32Bit = true;
}
