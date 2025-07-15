# flake.nix
{
  description = "GemBrawl: Top-down arena brawler with Gem heroes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {inherit system;};
      exportTemplateDir = "${pkgs.godotPackages_4_3.export-template}/share/godot/export_templates/4.3.stable";
    in {
      devShell = pkgs.mkShell {
        packages =
          (with pkgs.godotPackages_4_3; [
            godot
            export-template
          ])
          ++ (with pkgs; [
            fontconfig # Ensures proper font rendering
            alsa-lib # Ensures audio works
            libpulseaudio # For sound support
            xdg-utils # Open file dialogs
            git # Version control
          ]);
        GODOT4_EXPORT_TEMPLATES_DIR = exportTemplateDir;
        shellHook = ''
          # Use system export-template for reproducibility
          mkdir -p "$HOME/.local/share/godot/export_templates"
          ln -sf "${exportTemplateDir}" "$HOME/.local/share/godot/export_templates/4.3.stable"
        '';
      };
    });
}
