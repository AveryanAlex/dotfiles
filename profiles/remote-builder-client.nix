{ config, secrets, ... }:
{
  nix.buildMachines = [
    {
      hostName = "whale";
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      maxJobs = 2;
      speedFactor = 16;
      supportedFeatures = [
        "nixos-test"
        "benchmark"
        "big-parallel"
        "kvm"
      ];
      mandatoryFeatures = [ ];
      protocol = "ssh-ng";
      sshUser = "nix-remote-builder";
      sshKey = config.age.secrets.remote-builder-ssh-key.path;
      publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUN0eXhOVjhJUFNNSHVkSnJNYmVtY0s4Mkxvc1U5dGRORFYycmhmMFo5cHMgcm9vdEB3aGFsZQo=";
    }
  ];
  nix.distributedBuilds = true;

  age.secrets.remote-builder-ssh-key.file = "${secrets}/remote-builder-ssh-key.age";
}
