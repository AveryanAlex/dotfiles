{
  lib,
  config,
  ...
}:
{
  hm = {
    programs.waybar = {
      enable = true;
      systemd.enable = true;
      style = ''
        #waybar {
            font-family: "Fira Sans SemiBold";
            font-size: 13px;
        }

        #window {
            padding: 0 10px;
        }

        window#waybar {
            border: none;
            border-radius: 0;
            box-shadow: none;
            text-shadow: none;
            transition-duration: 0s;
            color: rgba(217, 216, 216, 1);
            background: rgba(0, 0, 0, 0.87);
        }

        window#waybar.solo {
            background: rgb(35, 31, 32);
            font-size: 15px;
        }

        #workspaces {
            margin: 0 2px;
        }

        #workspaces button {
            padding: 0 2px;
            color: rgba(217, 216, 216, 0.4);
            /* border: 3px solid rgba(217, 216, 216, 0);
            border-radius: 10px; */
        }

        #workspaces button.visible {
            color: rgba(217, 216, 216, 1);
        }

        #workspaces button.focused {
            border-top: 3px solid rgba(217, 216, 216, 1);
            border-bottom: 3px solid rgba(217, 216, 216, 1);
        }

        #workspaces button.urgent {
            background-color: #943432;
            color: white;
        }

        #workspaces button:hover {
            box-shadow: inherit;
            border-color: #d1be8b;
            color: #888888;
        }

        /* Repeat style here to ensure properties are overwritten as there's no !important and button:hover above resets the colour */

        #workspaces button.focused {
            color: white;
        }

        #pulseaudio {
            /* font-size: 26px; */
        }

        #custom-cpu_speed {
            min-width: 82px;
        }

        #custom-recorder {
        	font-size: 18px;
        	margin: 2px 7px 0px 7px;
        	color:#c9545d;
        }

        #tray,
        #clock,
        #mode,
        #battery,
        #temperature,
        #cpu,
        #memory,
        #network,
        #pulseaudio,
        #idle_inhibitor,
        #language,
        #backlight,
        #custom-storage,
        #custom-cpu_speed,
        #custom-powermenu,
        #custom-spotify,
        #custom-weather,
        #custom-mail,
        #custom-media {
            margin: 0px 0px 0px 10px;
            padding: 0 5px;
            /* border-top: 3px solid rgba(217, 216, 216, 0.5); */
        }

        #battery.warning {
            color: rgba(255, 210, 4, 1);
        }

        #battery.critical {
            color: rgba(238, 46, 36, 1);
        }

        #battery.charging {
            color: rgba(217, 216, 216, 1);
        }

        #custom-storage.warning {
            color: rgba(255, 210, 4, 1);
        }

        #custom-storage.critical {
            color: rgba(238, 46, 36, 1);
        }
      '';
      settings = [
        {
          height = 30;
          layer = "top";
          tray = {
            spacing = 10;
          };
          modules-left = [
            "tray"
            "hyprland/workspaces"
          ];
          modules-center = [
            "idle_inhibitor"
            "cpu"
            "memory"
            "disk"
          ];
          modules-right = [
            "pulseaudio"
            "backlight"
            (lib.optionalString (config.networking.hostName != "alligator") "upower")
            "network"
            "clock"
          ];
          "hyprland/workspaces" = {
            "format" = "{icon}";
            "on-scroll-up" = "hyprctl dispatch workspace e+1";
            "on-scroll-down" = "hyprctl dispatch workspace e-1";
          };
          idle_inhibitor = {
            format = "{icon}";
            format-icons = {
              activated = "";
              deactivated = "";
            };
          };
          clock = {
            format = "{:%H:%M}";
            format-alt = "{:%d.%m.%Y}";
            tooltip-format = "{:%H:%M | %d.%m.%Y}";
          };
          cpu = {
            format = "{usage}% ";
            tooltip = false;
          };
          memory = {
            format = "{}% ";
          };
          network = {
            format-wifi = "{essid} ({signalStrength}%) ";
            format-ethernet = "{ipaddr}/{cidr} ";
            tooltip-format = "{ifname} via {gwaddr} ";
            format-linked = "{ifname} (No IP) ";
            format-disconnected = "Disconnected ⚠";
            format-alt = "{ifname}: {ipaddr}/{cidr}";
          };
          pulseaudio = {
            format = "{volume}% {icon} {format_source}";
            format-bluetooth = "{volume}% {icon} {format_source}";
            format-bluetooth-muted = " {icon} {format_source}";
            format-muted = " {format_source}";
            format-source = "{volume}% ";
            format-source-muted = "";
            format-icons = {
              headphone = "";
              hands-free = "";
              headset = "";
              phone = "";
              portable = "";
              car = "";
              default = [
                ""
                ""
                ""
              ];
            };
            on-click = "pavucontrol";
          };
          temperature = {
            critical-threshold = 80;
            format = "{temperatureC}°C {icon}";
            format-icons = [
              ""
              ""
              ""
            ];
          };
          "wlr/workspaces" = {
            "format" = "{icon}";
            "on-scroll-up" = "hyprctl dispatch workspace e+1";
            "on-scroll-down" = "hyprctl dispatch workspace e-1";
            "on-click" = "activate";
          };
        }
      ];
    };
  };
}
