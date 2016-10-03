{ config, pkgs, ... }: {

  environment.systemPackages = with pkgs; [
    bc
    bind # nslookup, dig
    binutils # strings
    dtrx
    elinks
    ethtool
    file
    gdb
    git
    htop
    iftop
    iperf
    lshw
    lsof
    mosh
    mtr
    ncdu
    nix-prefetch-git
    nix-prefetch-zip
    nix-repl
    nox
    openssl # for speed-testing via 'openssl speed'
    pciutils # lspci
    psmisc # killall
    pv
    rxvt_unicode.terminfo
    screen
    tcpdump
    traceroute
    tree
    unzip
    usbutils # lsusb
    vim
    wget
    zip
    zsh
  ];
  system.extraDependencies = with pkgs; [ stdenv busybox busybox.src.mirrorsFile ];

  networking.domain = "dezgeg.me";
  networking.firewall.enable = false;
  networking.useNetworkd = true;
  networking.nameservers = ["8.8.8.8" "8.8.4.4"];

  services.openssh.enable = true;
  services.openssh.ports = [222];

  programs.bash.enableCompletion = true;
  programs.ssh.setXAuthLocation = true; # forward X11 connections
  programs.ssh.startAgent = false;

  services.nixosManual.enable = false; # slows down nixos-rebuilds
  services.nscd.enable = false;
  services.cron.enable = false;
  services.ntp.enable = false;
  services.udisks2.enable = false;
  security.audit.enable = false;

  services.timesyncd.enable = true;
  services.resolved.enable = true;
  systemd.coredump.enable = true;

  security.sudo.wheelNeedsPassword = false;
  services.mingetty.autologinUser = "tmtynkky";
  users.mutableUsers = false;

  users.extraUsers.tmtynkky = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = ["wheel" "networkmanager"];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAtAd4YHD7l/CopsieHHUHPiwFA0hkZjDtW/WYcVh1hPW5CxM7v8pT5bZkov/g5fAl6KT8GdMGU3gr35+POU2Mn3isI+GYkevTdmzkTtXSvq32V7N0RbUPNOfgi0o8HVZgVo7V3PluyXNeImiURfWKkb6i/VY87ZWqTzzr0dgbFgZasHO08T8Ym+PynffACXNa7eFxVJSX0pp2tjDcMM8EJjvrd+F2A8Tb3JSkRLPH1ZqHsL/xTswWIdvqPhk3YYzrIXzeur7MA+9n8CKmshdxqWAiv6lFXjkFGQjrdgxLHXCUA1OKkwhIbbBKaZdG6JLb7Fi9Ft9rp3876bFzBI26tQ=="
    ];
  };

  boot.loader.grub.version = 2;
  boot.loader.timeout = 1;
  boot.blacklistedKernelModules = ["tpm_tis" "pcspkr"];

  fileSystems."/tmp" = {
    device = "nodev";
    fsType = "tmpfs";
    options = ["size=4G" "nr_inodes=300000"];
  };

  services.journald.extraConfig = "SystemMaxUse=100M";

  time.timeZone = "Europe/Helsinki";
  i18n.consoleKeyMap = "dvorak";
  i18n.defaultLocale = "en_US.UTF-8";

  nixpkgs.config.allowUnfree = true;
  nix.package = pkgs.nixUnstable;
  nix.trustedUsers = ["tmtynkky"];
  nix.binaryCachePublicKeys = [
    "hydra.nixos.org-1:CNHJZBh9K4tP3EKF6FkkgeVYsS3ohTl+oS0Qa8bezVs="
    "nixos-arm.dezgeg.me-1:xBaUKS3n17BZPKeyxL4JfbTqECsT+ysbDJz29kLFRW0=%"
  ];
  nix.extraOptions = ''
    build-cache-failure = true
  '';
}
