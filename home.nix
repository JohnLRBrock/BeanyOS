{
    pkgs,
    ...
}:
let
  inherit (import ./variables.nix) gitUsername gitEmail;
in
{
  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      bbenoist.nix
      dracula-theme.theme-dracula
      vscodevim.vim
    ];
  };

  # Install git
  programs.git = {
    enable = true;
    userName = "${gitUsername}";
    userEmail = "${gitEmail}";
  };

  home.stateVersion = "23.11";
  # home.file."Pictures/Wallpapers" = {
  #   source = ../../config/wallpapers;
  #   recursive = true;
  # }
}