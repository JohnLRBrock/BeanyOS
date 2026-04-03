nix-channel --update
sudo nix flake update
sudo nixos-rebuild switch --flake .#laptop