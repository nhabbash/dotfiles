# Starship prompt configuration
{ config, pkgs, lib, ... }:

{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      format = lib.concatStrings [
        "[░▒▓](#a3aed2)"
        "[  ](bg:#a3aed2 fg:#090c0c)"
        "[](bg:#769ff0 fg:#a3aed2)"
        "$directory"
        "[](fg:#769ff0 bg:#394260)"
        "$git_branch"
        "$git_status"
        "[](fg:#394260 bg:#2d344b)"
        "\${custom.nodejs}"
        "[](fg:#2d344b)"
        "\n$character"
      ];

      directory = {
        style = "fg:#e3e5e5 bg:#769ff0";
        format = "[ $path ]($style)";
        truncation_length = 3;
        truncation_symbol = ".../";
      };

      git_branch = {
        symbol = "";
        style = "bg:#394260";
        format = "[[ $symbol $branch ](fg:#769ff0 bg:#394260)]($style)";
      };

      git_status = {
        style = "bg:#394260";
        format = "[[($all_status$ahead_behind )](fg:#769ff0 bg:#394260)]($style)";
      };

      custom.nodejs = {
        command = "node --version | tr -d '\\n'";
        when = true;
        symbol = "󰎙";
        style = "bg:#2d344b";
        format = "[[ $symbol $output ](fg:#769ff0 bg:#2d344b)]($style)";
        disabled = false;
      };

      kubernetes = {
        symbol = "☸";
        style = "bg:#212736";
        format = "[[ $symbol ($context \\($namespace\\)) ](fg:#769ff0 bg:#212736)]($style)";
        disabled = false;
      };
    };
  };
}
