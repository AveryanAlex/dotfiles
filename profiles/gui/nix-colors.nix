{ inputs, ... }:
{
  home-manager.users.alex = inputs.nix-colors.homeManagerModule;
}
