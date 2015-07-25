{ config, pkgs, lib, ... }: {
  imports = [
      ./common.nix
  ];

  # Remove this!
  services.openssh.ports = lib.mkForce [22];

  services.openssh.extraConfig = ''
    AllowUsers tmtynkky root@10.0.0.1
  '';

  boot.consoleLogLevel = 8;
  boot.kernelParams = ["console=ttyS0,115200n8"];

  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  hardware.enableAllFirmware = true;
  hardware.opengl.enable = lib.mkDefault false;
  powerManagement.enable = false;

  nix.binaryCaches = lib.mkForce ["http://10.0.0.1:5000"];
  nix.maxJobs = 4;
  nix.buildCores = 0;
  nix.extraOptions = ''
    gc-keep-derivations = false
  '';

  users.extraUsers.root = {
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC0k1X6oCcPXuIor0q3jZIQw1GIx2JkvuvvOOL8xmCm0ArFOxhHTznjZml2Mp54prHZy54KAWNixpV+qOEngCVzG2EFG0bI724IS5nrIPATARros6nzzAiQW+J15zXa83RBLD/74DdCcvFrNMp905d2Vw+kupA1aTToEwsMnrYG1N/X2PGA7OT7QZhrjTUtJiPj+Q46mxf+5U6VLMqkJLnxePp8RnHlq0whncGbuF9fFWVcnZUkUOvLIQhENbAMv/Y9yQ3lN0eB+od032zNacuGpysbT0QDDAeCFtr43naP1vd2ZY6IspRUOHjAJzxpBzWvOM3yDZQ74tqS2da0z35v"
    ];
  };
}
