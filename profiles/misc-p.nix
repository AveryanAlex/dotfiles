{ lib, ... }:
{
  systemd.defaultUnit = "graphical.target";
}
