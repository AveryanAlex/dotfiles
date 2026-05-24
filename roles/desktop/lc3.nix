{ pkgs, ... }:
{
  # ─── Bluetooth ──────────────────────────────────────────────────────────
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        # Required for LE Audio (BAP). Enables D-Bus experimental interfaces.
        Experimental = true;
        # Enables the kernel ISO socket UUID, which BAP needs for CIS streams.
        KernelExperimental = "6fbaf188-05e0-496a-9885-d6ddfdb4e03e";
        # Allow both Classic and LE; do NOT set "le" here or Classic A2DP breaks.
        ControllerMode = "dual";
        # Nice-to-haves
        FastConnectable = true;
        JustWorksRepairing = "always";
      };
    };
  };

  # ─── PipeWire + WirePlumber ─────────────────────────────────────────────
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    # alsa.support32Bit = true;
    pulse.enable = true;

    # Enable BAP (LE Audio) roles in addition to Classic profiles.
    # The default WirePlumber role list already includes bap_*, but if anything
    # else in your config sets bluez5.roles, that override wins — so we set
    # the full list explicitly here to be safe.
    wireplumber.extraConfig."51-bluez-le-audio" = {
      "monitor.bluez.properties" = {
        "bluez5.enable-sbc-xq" = true;
        "bluez5.enable-msbc" = true;
        "bluez5.enable-hw-volume" = true;
        "bluez5.roles" = [
          "a2dp_sink"
          "a2dp_source"
          "bap_sink"
          "bap_source"
          "bap_bc_sink"
          "bap_bc_source"
          "hfp_hf"
          "hfp_ag"
          "hsp_hs"
          "hsp_ag"
        ];
        # Optional: list of A2DP codecs; comment out to keep all enabled.
        # "bluez5.codecs" = [ "sbc" "sbc_xq" "aac" "ldac" "lc3" ];
      };
    };
  };

  # Useful tools to have around for debugging
  environment.systemPackages = with pkgs; [
    bluez
    bluez-tools
    pavucontrol
    pwvucontrol
  ];
}
