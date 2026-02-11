{ pkgs, ... }:
{
  # services.avahi.enable = true;
  # services.avahi.openFirewall = true;

  services.printing = {
    enable = true;
    stateless = true;
    drivers = with pkgs; [ hplip ];
    cups-pdf.enable = true;
  };

  hardware.printers.ensurePrinters = [
    {
      name = "DeskJet_5820";
      model = "drv:///hp/hpcups.drv/hp-deskjet_5820_series.ppd";
      deviceUri = "hp:/net/DeskJet_5820_series?ip=192.168.3.10";
      ppdOptions = {
        "PageSize/Media Size" = "A4";
        "ColorModel/Output Mode" = "RGB";
        "MediaType/Media Type" = "Plain";
        "OutputMode/Print Quality" = "Best";
      };
    }
  ];
  hardware.printers.ensureDefaultPrinter = "DeskJet_5820";

  environment.systemPackages = with pkgs; [
    simple-scan
    hplip
  ];
}
