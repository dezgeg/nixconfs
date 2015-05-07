{ config, pkgs, ... }: {

  environment.systemPackages = with pkgs; [
    bind # nslookup, dig
    binutils # strings
    dtrx
    elinks
    file
    gdb
    git
    htop
    iftop
    lshw
    lsof
    mtr
    ncdu
    nix-repl
    psmisc # killall
    pv
    rxvt_unicode.terminfo
    screen
    tcpdump
    traceroute
    tree
    vim
    wget
    zsh
  ];

  networking.domain = "dezgeg.me";
  networking.firewall.enable = false;
  services.openssh.enable = true;
  services.openssh.ports = [222];

  services.nixosManual.enable = false; # slows down nixos-rebuilds
  services.nscd.enable = false;
  services.cron.enable = false;
  services.ntp.enable = false;
  services.timesyncd.enable = true;

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
  boot.tmpOnTmpfs = true;

  time.timeZone = "Europe/Helsinki";
  i18n = {
    consoleKeyMap = "dvorak";
    defaultLocale = "en_US.UTF-8";
  };

  nix.binaryCaches = [
    "https://cache.nixos.org/"
    "https://hydra.nixos.org/"
  ];
}
