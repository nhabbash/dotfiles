#!/usr/bin/env bash
set -f

input=$(cat)

# --- Parse stdin JSON ---
model=$(echo "$input" | jq -r '.model.display_name // .model.id // "?"' | sed 's/Claude //')
cwd=$(echo "$input" | jq -r '.cwd // ""')
transcript=$(echo "$input" | jq -r '.transcript_path // ""')

ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
input_tokens=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // 0')
cache_create=$(echo "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0')
cache_read=$(echo "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')

if [ -z "$pct" ] || [ "$pct" = "null" ]; then
  total_used=$((input_tokens + cache_create + cache_read))
  if [ "$ctx_size" -gt 0 ] 2>/dev/null; then
    pct=$((total_used * 100 / ctx_size))
  else
    pct=0
  fi
else
  pct=$(printf "%.0f" "$pct" 2>/dev/null || echo 0)
fi
total_used=$((input_tokens + cache_create + cache_read))

# --- Context bar (10 chars, ensure fills at low %) ---
filled=$((pct / 10))
[ "$pct" -gt 0 ] && [ "$filled" -eq 0 ] && filled=1
[ "$filled" -gt 10 ] && filled=10
empty=$((10 - filled))
bar=""
for ((i=0; i<filled; i++)); do bar+="█"; done
for ((i=0; i<empty; i++)); do bar+="░"; done

if [ "$pct" -lt 60 ]; then
  bar_color="\033[38;5;78m"
elif [ "$pct" -lt 80 ]; then
  bar_color="\033[38;5;221m"
else
  bar_color="\033[38;5;204m"
fi

# --- Tokens ---
if [ "$total_used" -ge 1000000 ] 2>/dev/null; then
  tokens_display=$(printf "%.1fM" "$(echo "$total_used / 1000000" | bc -l 2>/dev/null || echo 0)")
elif [ "$total_used" -ge 1000 ] 2>/dev/null; then
  tokens_display=$(printf "%.0fk" "$(echo "$total_used / 1000" | bc -l 2>/dev/null || echo 0)")
else
  tokens_display="$total_used"
fi

# --- Directory ---
if [ -n "$cwd" ]; then
  dir_display=$(echo "$cwd" | sed "s|$HOME|~|")
  depth=$(echo "$dir_display" | awk -F'/' '{print NF}')
  if [ "$depth" -gt 3 ]; then
    dir_display="…/$(echo "$dir_display" | awk -F'/' '{print $(NF-1)"/"$NF}')"
  fi
else
  dir_display="~"
fi

# --- Git branch ---
branch=""
[ -n "$cwd" ] && branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null || true)

# --- Duration ---
duration=0
if [ -n "$transcript" ] && [ -f "$transcript" ]; then
  start_ts=$(stat -f %B "$transcript" 2>/dev/null || stat -c %W "$transcript" 2>/dev/null || echo 0)
  [ "$start_ts" -gt 0 ] 2>/dev/null && duration=$(( $(date +%s) - start_ts ))
fi
if [ "$duration" -ge 3600 ]; then
  time_display="$((duration/3600))h$(( (duration%3600)/60 ))m"
elif [ "$duration" -ge 60 ]; then
  time_display="$((duration/60))m"
else
  time_display="${duration}s"
fi

# --- Colors ---
dim="\033[2m"
rst="\033[0m"
c_model="\033[38;5;147m"
c_dir="\033[38;5;110m"
c_branch="\033[38;5;104m"
c_cyan="\033[36m"
c_magenta="\033[35m"
c_tok="\033[38;5;245m"
# ── LINE 1 ──
# Status dot reflects context pressure
if [ "$pct" -lt 60 ]; then
  dot="◉"
  dot_color="\033[38;5;78m"
elif [ "$pct" -lt 80 ]; then
  dot="◉"
  dot_color="\033[38;5;221m"
else
  dot="◉"
  dot_color="\033[38;5;204m"
fi
printf "${dot_color}%s${rst} ${c_model}%s${rst}" "$dot" "$model"
printf "  ${dim}│${rst}  ${bar_color}%s${rst} %s%%" "$bar" "$pct"
printf "  ${dim}│${rst}  ${c_tok}%s${rst}" "$tokens_display"
printf "  ${dim}│${rst}  ${dim}⏱${rst} %s" "$time_display"
printf "  ${dim}│${rst}  ${c_dir}%s${rst}" "$dir_display"
[ -n "$branch" ] && printf "  ${dim}│${rst}  ${c_branch}⎇ %s${rst}" "$branch"

# ── LINE 2: tools + agents (width-capped to prevent canvas bloat) ──
if [ -n "$transcript" ] && [ -f "$transcript" ]; then
  all_tools=$(grep -o '"type":"tool_use"[^}]*"name":"[^"]*"' "$transcript" 2>/dev/null \
    | grep -o '"name":"[^"]*"' \
    | sed 's/"name":"//;s/"//')

  if [ -n "$all_tools" ]; then
    tool_counts=$(echo "$all_tools" | sort | uniq -c | sort -rn)
    total_calls=$(echo "$all_tools" | wc -l | tr -d ' ')

    # Build line 2 as plain text first, then truncate
    line2="  ⚡ ($total_calls)"

    declare -A mcp_servers
    builtin_names=()
    top_n=0

    while IFS= read -r tc_line; do
      [ -z "$tc_line" ] && continue
      count=$(echo "$tc_line" | awk '{print $1}')
      name=$(echo "$tc_line" | awk '{print $2}')
      if [[ "$name" == mcp__* ]]; then
        server=$(echo "$name" | sed 's/^mcp__//;s/__.*$//')
        prev=${mcp_servers[$server]:-0}
        mcp_servers[$server]=$((prev + count))
      elif [[ "$name" != "Task" ]]; then
        if [ "$top_n" -lt 5 ]; then
          builtin_names+=("${name}x${count}")
          top_n=$((top_n + 1))
        fi
      fi
    done <<< "$tool_counts"

    for b in "${builtin_names[@]}"; do
      line2+="  $b"
    done
    [ "$top_n" -ge 5 ] && line2+="  …"

    if [ ${#mcp_servers[@]} -gt 0 ]; then
      line2+="  ·"
      for server in $(for k in "${!mcp_servers[@]}"; do echo "${mcp_servers[$k]} $k"; done | sort -rn | awk '{print $2}'); do
        cnt=${mcp_servers[$server]}
        line2+="  ${server}x${cnt}"
      done
    fi

    agent_count=$(echo "$all_tools" | grep -c '^Task$' || true)
    if [ "$agent_count" -gt 0 ] 2>/dev/null; then
      line2+="  · agents($agent_count)"
    fi

    # Truncate to terminal width to prevent Ink canvas width growth
    max_w=${COLUMNS:-80}
    if [ ${#line2} -gt "$max_w" ]; then
      line2="${line2:0:$((max_w - 1))}…"
    fi

    # Now output with colors
    echo
    printf "  ${dim}⚡${rst} ${dim}(${rst}%s${dim})${rst}" "$total_calls"

    n=0
    for b in "${builtin_names[@]}"; do
      bname="${b%x*}"
      bcount="${b##*x}"
      printf "  ${c_cyan}%s${rst}${dim}x%s${rst}" "$bname" "$bcount"
      n=$((n + 1))
    done
    [ "$top_n" -ge 5 ] && printf "  ${dim}…${rst}"

    if [ ${#mcp_servers[@]} -gt 0 ]; then
      printf "  ${dim}·${rst}"
      for server in $(for k in "${!mcp_servers[@]}"; do echo "${mcp_servers[$k]} $k"; done | sort -rn | awk '{print $2}'); do
        cnt=${mcp_servers[$server]}
        printf "  ${c_magenta}%s${rst}${dim}x%s${rst}" "$server" "$cnt"
      done
    fi

    if [ "$agent_count" -gt 0 ] 2>/dev/null; then
      printf "  ${dim}·${rst}  ${dim}agents(${rst}%s${dim})${rst}" "$agent_count"
    fi
  fi
fi

echo
