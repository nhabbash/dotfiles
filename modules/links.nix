{ lib, features }:

{
  # Shell
  ".config/zsh/core.zsh" = "configs/zsh/core.zsh";
  ".config/zsh/aliases.zsh" = "configs/zsh/aliases.zsh";
  ".config/zsh/functions.zsh" = "configs/zsh/functions.zsh";
  ".config/zsh/claude.zsh" = "configs/zsh/claude.zsh";
  ".config/zsh/zellij.zsh" = "configs/zsh/zellij.zsh";
  ".config/zsh/work.zsh" = "configs/zsh/work.zsh";
  ".config/zsh/personal.zsh" = "configs/zsh/personal.zsh";
  ".config/starship.toml" = "configs/starship.toml";

  # Git & tools
  ".gitconfig" = "configs/git/config";
  ".config/jj/config.toml" = "configs/jj/config.toml";
  ".config/gh/config.yml" = "configs/gh/config.yml";
  ".tmux.conf" = "configs/tmux/tmux.conf";

  # Neovim (LazyVim)
  ".config/nvim" = "configs/nvim";

  # Claude Code
  ".claude/CLAUDE.md" = "configs/claude/CLAUDE.md";
  ".claude/statusline.sh" = "configs/claude/statusline.sh";

  # Agents
  ".config/agents" = "configs/agents";

  # Zellij
  ".config/zellij" = "configs/zellij";
}
// lib.optionalAttrs features.gui {
  ".config/kitty" = "configs/kitty";
  ".config/ghostty/shaders" = "configs/ghostty/shaders";
}
// lib.optionalAttrs features.aerospace {
  "Library/Application Support/com.mitchellh.ghostty/config" = "configs/ghostty/config";
  ".config/aerospace" = "configs/aerospace";
  ".simplebarrc" = "configs/simplebarrc";
  ".local/bin/aerospace-summon-workspace-here.sh" = "scripts/aerospace-summon-workspace-here.sh";
  ".local/bin/aerospace-clean.sh" = "scripts/aerospace-clean.sh";
  ".local/bin/aerospace-refresh-simple-bar.sh" = "scripts/aerospace-refresh-simple-bar.sh";
}
// lib.optionalAttrs features.hammerspoon {
  ".hammerspoon" = "configs/hammerspoon";
}
// lib.optionalAttrs (features.ghostty && !features.darwin) {
  ".config/ghostty/config" = "configs/ghostty/config";
}
