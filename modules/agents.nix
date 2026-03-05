# AI agent instructions and Claude Code configuration
{ config, pkgs, ... }:

{
  xdg.configFile."agents" = {
    source = ../configs/agents;
    recursive = true;
  };

  home.file.".claude/CLAUDE.md".source = ../configs/claude/CLAUDE.md;
}
