{ pkgs, ... }:
let
  libraries = with pkgs; [
    glib
    nss
    nspr
    dbus
    at-spi2-atk
    cups
    libdrm
    gtk3
    pango
    cairo
    libx11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libgbm
    expat
    libxcb
    libxkbcommon
    alsa-lib
    libGL
    ocl-icd
    libcxx
    libpulseaudio
    wayland
    fontconfig
    freetype
    # gss
    # libgssglue
    krb5
    libva
    mdk-sdk
  ];
in
{
  # environment.sessionVariables.LD_LIBRARY_PATH = "${lib.makeLibraryPath ([
  #     pkgs.stdenv.cc.cc
  #   ]
  #   ++ libraries)}";

  services.envfs.enable = true;

  programs.nix-ld = {
    enable = true;
    inherit libraries;
  };
}
