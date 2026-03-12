# AI agent instructions and Claude Code configuration
{ config, dotfilesDir, ... }:

let
  mkLink = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${path}";
in
{
  xdg.configFile."agents".source = mkLink "configs/agents";

  home.file = {
    ".claude/CLAUDE.md".source = mkLink "configs/claude/CLAUDE.md";
    ".claude/statusline.sh".source = mkLink "configs/claude/statusline.sh";
  };
}
