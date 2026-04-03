# Personal-specific config — loaded only on personal machines

# Local service aliases (localias)
export LOCALIAS_CONFIGFILE="$HOME/.config/localias.yaml"

# AeroSpace
alias aerospace-clean='aerospace list-windows --all --json | jq -r ".[] | select(.\"window-title\"==\"\") | .\"window-id\"" | xargs -n1 aerospace close --window-id'

export PATH="/Users/nassim/.cache/.bun/bin:$PATH"
