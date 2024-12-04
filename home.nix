{
    pkgs,
    ...
}:
{
  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      bbenoist.nix
      dracula-theme.theme-dracula
      vscodevim.vim
    ];
  };

  home.stateVersion = "23.11";
  # home.file."Pictures/Wallpapers" = {
  #   source = ../../config/wallpapers;
  #   recursive = true;
  # }
}