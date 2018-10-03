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
  boot.kernelParams = ["nopti"];

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
    gitAndTools.hub
    gnumake
    picocom
    python2
    python3
    ruby
    sshfs
    valgrind

    # X11 stuff.
    claws-mail
    gnuplot_qt
    google-chrome
    kdeApplications.okular
    mpv
    networkmanagerapplet
    pavucontrol
    redshift
    rxvt_unicode
    scrot
    xclip
    xorg.xbacklight
    xorg.xmodmap

    # Gaming.
    steam
    wine

    config.boot.kernelPackages.perf
  ];

  networking.hostName = "thinkpad";
  networking.hostId = "119933b3";
  networking.networkmanager.enable = true;
  networking.extraHosts = builtins.readFile ./hosts-blocklist.txt;

  services.ddclient = {
    enable = true;
    protocol = "namecheap";
    domains = ["@"];
    username = "dezgeg.me";
    server = "dynamicdns.park-your-domain.com";
    # password comes from ./passwords.nix
  };

  nix.maxJobs = 4;
  nix.useSandbox = true;
  nix.package = pkgs.nixUnstable;

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
    videoDrivers = [ "intel" ];
  };
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.support32Bit = true;
  hardware.opengl.enable = true;
  hardware.opengl.driSupport32Bit = true;
}
