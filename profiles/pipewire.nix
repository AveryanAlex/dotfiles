{ pkgs, ... }:
{
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    # alsa.support32Bit = true;
    pulse.enable = true;
    extraConfig.pipewire."99-low-latency" = {
      "context.properties" = {
        "default.clock.quantum" = 512;
        "default.clock.min-quantum" = 64;
        "default.clock.max-quantum" = 1024;
      };
    };
  };

  services.pulseaudio.enable = false;

  hm.services.mpd.extraConfig = ''
    audio_output {
      type "pipewire"
      name "PipeWire"
    }
  '';

  environment.systemPackages = with pkgs; [
    pavucontrol
    pwvucontrol
  ];
}
