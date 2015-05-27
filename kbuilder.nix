{ config, pkgs, lib, ... }: {

  imports = [
      ./hardware-configuration.nix
      ./common.nix
      ./passwords.nix
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.kernelPackages = pkgs.linuxPackages_latest;

  environment.systemPackages = with pkgs; [
    picocom
  ];

  services.timesyncd.enable = lib.mkForce false; # Change this once systemd is updated
  services.nix-serve.enable = true;

  services.logind.extraConfig = ''
    HandleLidSwitch=ignore
  '';

  networking = {
    wireless.enable = true;

    hostName = "kbuilder";
    hostId = "c809225e";
    extraHosts = ''
      10.0.0.1 kbuilder
      10.0.0.2 raspi
      10.0.0.10 jetson
    '';

    firewall = {
      enable = lib.mkForce true;
      allowPing = true;
      logRefusedConnections = false;
      rejectPackets = false;
      allowedTCPPortRanges = [{ from = 220; to = 230; }];
      trustedInterfaces = ["enp9s0"];
    };
  };

  services.ddclient = {
    enable = true;
    protocol = "namecheap";
    domain = "kbuilder";
    username = "dezgeg.me";
    server = "dynamicdns.park-your-domain.com";
    # password comes from ./passwords.nix
  };

  services.nfs.server = {
    enable = true;
    createMountPoints = true;
    exports = ''
      /srv/nfs    10.0.0.0/8(rw,async,no_subtree_check,no_root_squash,nohide)
    '';
  };

  services.atftpd = {
    enable = true;
    root = "/srv/tftp";
  };

  services.dhcpd = {
    enable = true;
    interfaces = ["enp9s0"];
    extraConfig = ''
      option domain-name-servers 8.8.8.8, 8.8.4.4;
      option subnet-mask 255.0.0.0;
      option routers 10.0.0.1;

      default-lease-time 25920000;
      max-lease-time 25920000;

      subnet 10.0.0.0 netmask 255.0.0.0 {
        host raspi {
          hardware ethernet b8:27:eb:63:84:ca;
          fixed-address 10.0.0.2;
        }

        host jetson {
          hardware ethernet 00:04:4b:25:ae:c9;
          fixed-address 10.0.0.10;
          filename "/boot.scr.uimg";
          next-server 10.0.0.1;
        }
      }
    '';
  };

  networking.interfaces.enp9s0 = {
    ip4 = [{ address = "10.0.0.1"; prefixLength = 8; }];
  };

  networking.nat = {
    enable = true;
    externalInterface = "wlp5s0b1";
    internalInterfaces = ["enp9s0"];
    forwardPorts = [
      { sourcePort = 223; destination = "10.0.0.2:22"; }    # SSH on raspi
      { sourcePort = 224; destination = "10.0.0.10:22"; }   # SSH on jetson
      { sourcePort = 230; destination = "10.0.0.2:230"; }   # jetson-powerctl on raspi
    ];
  };

  nix.readOnlyStore = false; # nix-push --link fails otherwise
  nix.distributedBuilds = true;
  nix.buildMachines = [
    {
      hostName = "jetson";
      sshUser = "root";
      sshKey = "/etc/remote-builds/id_rsa";
      system = "armv7l-linux";
      maxJobs = 4;
    }
  ];
}
