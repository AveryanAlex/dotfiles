{ config, ... }:
{
  networking.wireguard.interfaces = {
    wgvpn = {
      ips = [ "10.8.7.1/24" ];
      listenPort = 51820;
      privateKeyFile = config.age.secrets.wg-key.path;
      peers = [
        {
          # Whale
          publicKey = "nt2xC/cl5opg4g5fUkvqKuUKORXLS/qGCikx7F0FBRQ=";
          allowedIPs = [ "10.8.8.0/24" ];
        }
        {
          # Sergievsky
          publicKey = "ZorGeiUIRES1FqTfuSEsbLsgt5h9+5B9sB/atwvxLnU=";
          allowedIPs = [ "10.8.7.230/32" ];
        }
        {
          # Ivanov Laptop
          publicKey = "G5EktXDDcm/dUwqjTrZK/LWzKe7VA055k+LtwQpaACU=";
          allowedIPs = [ "10.8.7.231/32" ];
        }
        {
          # Snigir Laptop
          publicKey = "N8bUSy8BnsjcIMWyOSRkQBuLhR4FbH1kDVSt0iTIVSA=";
          allowedIPs = [ "10.8.7.232/32" ];
        }
        {
          # Karaseva Laptop
          publicKey = "uAa4H16/SWRTpR3QXjLoeiJURzRaQ4Dw5DLYlADwDC8=";
          allowedIPs = [ "10.8.7.233/32" ];
        }
        {
          # DmPop router
          publicKey = "mrUbbvGn1cGOrWl0LnJyzIirUdwzoJRKH5grUhCxcxw=";
          allowedIPs = [ "10.8.7.234/32" ];
        }
        {
          # Vsevolod
          publicKey = "oKrAQE4sX4YjNf13qJz9IjprAH6YFhmt7CDUzXJVXl8=";
          allowedIPs = [ "10.8.7.240/32" ];
        }
        {
          # Kriger
          publicKey = "qxkQlt1Q9lHq+d48J9nkqTTC+Dzs2LHD+GycsSKDyyE=";
          allowedIPs = [ "10.8.7.241/32" ];
        }
        {
          # Ivanov
          publicKey = "bqkblOYoMi69RAIvJTy/zhovdUR+2O7JVaXoUqBXM2I=";
          allowedIPs = [ "10.8.7.242/32" ];
        }
        {
          # Tihonov
          publicKey = "mi4FUaRyD2yIbVtX1jC7cY7XXg6rUELcpAUyN+N7lU0=";
          allowedIPs = [ "10.8.7.243/32" ];
        }
        {
          # Despectdr
          publicKey = "/BRUH/MivTgVsGeTINUQ5pZDtX8nzrEv1vy+wNJE0Ws=";
          allowedIPs = [ "10.8.7.244/32" ];
        }
        {
          # Khrustaleva
          publicKey = "fZS0Loc8VTcARnokFwR4pgTiP+warZLa2IYHefiD8ho=";
          allowedIPs = [ "10.8.7.245/32" ];
        }
        {
          # Kazakova
          publicKey = "eoofp8UhHTo9SAgSDQmBKrqeF2me1goHIunWWE4Og1c=";
          allowedIPs = [ "10.8.7.246/32" ];
        }
        {
          # Karaseva
          publicKey = "dBmTwssDWdv+kQfnDl1sMdF7P6+E3szdJPud34tWq1k=";
          allowedIPs = [ "10.8.7.247/32" ];
        }
        {
          # Swan
          publicKey = "nQ5xDVQnHI9nPDXW79z7Ks5FHE0o0bqxA5ZKzh9dgEU=";
          allowedIPs = [ "10.8.7.248/32" ];
        }
        {
          # Poplik
          publicKey = "s4xNXZAq83WzDbIA9w4Ori9MrPuA8lsYKYRldfcrrHc=";
          allowedIPs = [ "10.8.7.249/32" ];
        }
        {
          # Alligator
          publicKey = "FtRuoT3cvVFGq4DGbBNMSEYDvhygFvMDAHWEnSUgfjo=";
          allowedIPs = [ "10.8.7.250/32" ];
        }
        {
          # Semenkova
          publicKey = "BFtu1jwSTG81fmVOfO8r46430bBfabPQfW30uovp0lw=";
          allowedIPs = [ "10.8.7.251/32" ];
        }
        {
          # Buzurtanova
          publicKey = "F9IpR8uhuhvG798d6MeFgys7Ovjkr2EblitLUjrjS1I=";
          allowedIPs = [ "10.8.7.252/32" ];
        }
        {
          # Kazakova Laptop
          publicKey = "iJqSgxiEwYey2055X8Hp4TlYyG2oiX7LQU2e2A3jj3o=";
          allowedIPs = [ "10.8.7.253/32" ];
        }
        {
          # Hamster
          publicKey = "tLUkMc4x9uZSSHl6AmjC+Ui2W9hbToVW0z1h027q828=";
          allowedIPs = [ "10.8.7.254/32" ];
        }
      ];
    };
  };
}
