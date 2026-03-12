# Work-specific config — loaded only on work machines

# Monday.com company dotfiles
[[ -f ~/dotfiles/.bash_profile ]] && source ~/dotfiles/.bash_profile
unalias claude 2>/dev/null

# Monday-specific paths
export PATH="$HOME/.monday-mirror/bin:$PATH"
export NODE_EXTRA_CA_CERTS="$HOME/.certs/all-ca-bundle.pem"
export SSL_CERT_FILE="$HOME/.certs/all-ca-bundle.pem"

# NVM (for monday-mirror)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Pyenv
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)" 2>/dev/null

# AWS
export AWS_PROFILE=default
export AWS_REGION=us-east-1

# GlobalProtect VPN control
disable_vpn() {
  echo "disabling vpn"
  launchctl remove com.paloaltonetworks.gp.pangps
  launchctl remove com.paloaltonetworks.gp.pangpa
}

enable_vpn() {
  echo "enabling vpn"
  launchctl load /Library/LaunchAgents/com.paloaltonetworks.gp.pangpa.plist
  launchctl load /Library/LaunchAgents/com.paloaltonetworks.gp.pangps.plist
}

# Kill orphaned MCP servers and stuck node processes
cleanup-mcp() {
  pkill -9 -f notebooklm-mcp 2>/dev/null && echo "killed notebooklm-mcp" || echo "no notebooklm-mcp running"
  pkill -9 -f "node.*vitest" 2>/dev/null && echo "killed stuck vitest" || echo "no stuck vitest"
}

# Claude Code: use opus on work machine (1M context via provider)
export ANTHROPIC_MODEL="claude-opus-4-6[1m]"

alias cursorcli='agent'
alias opencode='AWS_REGION= AWS_PROFILE= command opencode'
