{ config, pkgs, ... }: {

  imports = [
      ./hardware-configuration.nix
      ./common.nix
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  networking.hostName = "nixvm";
  networking.hostId = "46ea9ef1";

  environment.systemPackages = with pkgs; [
    nox

    # My misc packages
    dvorak7min
    bastet

    # Random testing
    # cool-retro-term
    # gtypist
    # stunnel
    # dosbox
    # wireshark-cli

    # Installer testing
    calamares
  ];

  services.xserver = {
    enable = true;
    autorun = true;

    xkbVariant = "dvorak";
    desktopManager.xterm.enable = true;
    desktopManager.default = "xterm";
    windowManager.fluxbox.enable = true;
    windowManager.default = "fluxbox";

    displayManager.auto = {
      enable = true;
      user = "tmtynkky";
    };
  };
}
