{
  description = "A simple NixOS flake";

  inputs = {
    # NixOS official package source, using the nixos-23.11 branch here
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    stylix.url = "github:danth/stylix";
    musnix.url = "github:musnix/musnix";
  };

  outputs = { self, nixpkgs, musnix, home-manager, ... }@inputs: {
    nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hosts
        ./hosts/desktop
        ./modules/audio.nix
        ./modules/nvidia-drivers.nix
        inputs.stylix.nixosModules.stylix
        inputs.musnix.nixosModules.musnix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.john = import ./home.nix;
        }
      ];
    };
    nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hosts
        ./hosts/laptop
        inputs.stylix.nixosModules.stylix
        inputs.musnix.nixosModules.musnix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.john = import ./home.nix;
        }
      ];
    };
  };
}