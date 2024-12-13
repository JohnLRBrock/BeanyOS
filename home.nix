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
    enableUpdateCheck = false;
    extensions = with pkgs.vscode-extensions; [
      bbenoist.nix
      dracula-theme.theme-dracula
      asvetliakov.vscode-neovim
      oderwat.indent-rainbow
    ];
    userSettings = {
      # "editor.fontFamily" = "'DejaVu Sans Mono'";
      # "terminal.integrated.fontFamily" = "'DejaVu Sans Mono'";
      "workbench.colorTheme" = "Stylix";
      "extensions.experimental.affinity" = {
        "asvetliakov.vscode-neovim" = 1;
      };
    };
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