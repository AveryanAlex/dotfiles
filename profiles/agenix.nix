{ inputs, ... }:
{
  imports = [
    inputs.ragenix.nixosModules.age
  ];
}
