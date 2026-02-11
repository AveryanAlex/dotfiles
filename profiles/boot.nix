{ lib, ... }:
{
  boot = {
    loader = {
      timeout = lib.mkForce 3;
    };
    kernelParams = [
      "modeset"
      "nofb"
    ];

    consoleLogLevel = 3;
    kernel.sysctl."kernel/sysrq" = 1;
  };

  persist.state.files = [ "/etc/machine-id" ];
}
