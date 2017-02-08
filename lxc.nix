{ config, pkgs, lib, ... }: {
  imports = [ ./common.nix ];

  boot.isContainer = true;
  networking.hostName = "lxc";
  networking.useDHCP = false;

  # nixos-rebuild requires a "system" profile
  boot.postBootCommands = ''
    ${config.nix.package.out}/bin/nix-env -p /nix/var/nix/profiles/system --set /run/current-system
  '';

  # Install new init script
  system.activationScripts.installInitScript = ''
    ln -fs $systemConfig/init /init
  '';
}
