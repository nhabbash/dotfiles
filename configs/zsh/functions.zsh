# Shared functions — loaded on all machines

function _agent_sessions_script() {
  echo "${DOTFILES_DIR:-$HOME/.dotfiles}/scripts/agent-sessions.sh"
}

function _agent_sessions_registry_dir() {
  if [[ -n "${AI_SESSION_REGISTRY_DIR:-}" ]]; then
    echo "$AI_SESSION_REGISTRY_DIR"
  else
    echo "${XDG_DATA_HOME:-$HOME/.local/share}/agent-sessions"
  fi
}

function _agent_sessions_record() {
  local launch_id="$1"
  local agent_type="$2"
  local entry_status="$3"
  local resume_id="$4"
  local started_at="$5"
  local completed_at="$6"
  local cwd="$7"
  local launch_cmd="$8"
  local note="${9:-}"
  local entry_kind="${10:-launch}"

  bash "$(_agent_sessions_script)" record \
    "$launch_id" "$agent_type" "$entry_status" "$resume_id" "$started_at" "$completed_at" "$cwd" "$launch_cmd" "$note" "$entry_kind"
}

function _agent_sessions_lookup_field() {
  local launch_id="$1"
  local field="$2"
  bash "$(_agent_sessions_script)" lookup-field "$launch_id" "$field"
}

function _agent_sessions_extract_resume_id() {
  local agent_type="$1"
  shift

  case "$agent_type" in
    codex)
      if [[ "${1:-}" == "resume" && -n "${2:-}" && "${2:-}" != -* ]]; then
        echo "$2"
      fi
      ;;
    claude)
      local i=1
      while [[ $i -le $# ]]; do
        local arg="${@[i]}"
        local next="${@[$((i + 1))]:-}"
        if [[ "$arg" == --resume=* || "$arg" == --session-id=* ]]; then
          echo "${arg#*=}"
          return 0
        fi
        if [[ "$arg" == "--resume" || "$arg" == "-r" || "$arg" == "--session-id" ]]; then
          if [[ -n "$next" && "$next" != -* ]]; then
            echo "$next"
            return 0
          fi
        fi
        ((i++))
      done
      ;;
    cursor-agent)
      local i=1
      while [[ $i -le $# ]]; do
        local arg="${@[i]}"
        local next="${@[$((i + 1))]:-}"
        if [[ "$arg" == --resume=* ]]; then
          echo "${arg#*=}"
          return 0
        fi
        if [[ "$arg" == "--resume" ]]; then
          if [[ -n "$next" && "$next" != -* ]]; then
            echo "$next"
            return 0
          fi
        fi
        ((i++))
      done
      ;;
  esac
}

function _agent_sessions_start_resolver() {
  local launch_id="$1"
  local agent_type="$2"
  local resolver="$3"
  local cwd="$4"
  local launch_cmd="$5"
  local started_at="$6"

  (
    local attempt maybe
    for attempt in {1..45}; do
      sleep 2
      maybe="$(bash "$(_agent_sessions_script)" resolve "$resolver" "$cwd" "$started_at" || true)"
      if [[ -n "$maybe" ]]; then
        bash "$(_agent_sessions_script)" record \
          "$launch_id" "$agent_type" "running" "$maybe" "$started_at" "0" "$cwd" "$launch_cmd" "resume id resolved while session is running" "launch"
        exit 0
      fi
    done
  ) >/dev/null 2>&1 &

  echo $!
}

function _agent_sessions_run_with_tracking() {
  local agent_type="$1"
  local binary="$2"
  local resolver="$3"
  shift 3

  local cwd="$PWD"
  local started_at launch_id launch_cmd exit_code completed_at resume_id capture_status note should_resolve entry_kind explicit_resume_id watcher_pid existing_resume_id

  started_at="$(date +%s)"
  launch_id="${agent_type}-${started_at}-$$-${RANDOM}"
  launch_cmd="$binary${*:+ }$*"
  should_resolve="${AI_SESSION_TRACKING_SKIP_RESOLVE:-0}"
  if [[ "$should_resolve" == "1" ]]; then
    should_resolve=0
  else
    should_resolve=1
  fi

  case " $* " in
    *" --help "*|*" -h "*|*" --version "*|*" -V "*|*" help "*)
      should_resolve=0
      ;;
  esac
  if [[ "$should_resolve" == "1" ]]; then
    entry_kind="launch"
  else
    entry_kind="probe"
  fi
  explicit_resume_id="$(_agent_sessions_extract_resume_id "$agent_type" "$@" || true)"

  if [[ -n "$explicit_resume_id" ]]; then
    _agent_sessions_record "$launch_id" "$agent_type" "running" "$explicit_resume_id" "$started_at" "0" "$cwd" "$launch_cmd" "resume id provided in launch arguments" "$entry_kind"
  else
    _agent_sessions_record "$launch_id" "$agent_type" "pending" "" "$started_at" "0" "$cwd" "$launch_cmd" "launch recorded" "$entry_kind"
  fi

  watcher_pid=""
  if [[ "$should_resolve" == "1" && -z "$explicit_resume_id" ]]; then
    watcher_pid="$(_agent_sessions_start_resolver "$launch_id" "$agent_type" "$resolver" "$cwd" "$launch_cmd" "$started_at")"
  fi

  "$binary" "$@"
  exit_code=$?
  completed_at="$(date +%s)"
  if [[ -n "$watcher_pid" ]]; then
    kill "$watcher_pid" >/dev/null 2>&1 || true
  fi
  if [[ "$should_resolve" == "1" ]]; then
    resume_id="$(bash "$(_agent_sessions_script)" resolve "$resolver" "$cwd" "$started_at" || true)"
  else
    resume_id=""
  fi
  if [[ -z "$resume_id" ]]; then
    existing_resume_id="$(_agent_sessions_lookup_field "$launch_id" "resume_id" || true)"
    if [[ -n "$existing_resume_id" && "$existing_resume_id" != "null" ]]; then
      resume_id="$existing_resume_id"
    elif [[ -n "$explicit_resume_id" ]]; then
      resume_id="$explicit_resume_id"
    fi
  fi

  if [[ -n "$resume_id" ]]; then
    capture_status="captured"
    if [[ -n "$explicit_resume_id" ]]; then
      note="session exited after running with explicit resume id"
    else
      note="resume id resolved from local state"
    fi
  else
    capture_status="unresolved"
    if [[ "$should_resolve" == "1" ]]; then
      note="resume id not resolved automatically"
    else
      note="resolution skipped for non-session command"
    fi
  fi

  _agent_sessions_record "$launch_id" "$agent_type" "$capture_status" "$resume_id" "$started_at" "$completed_at" "$cwd" "$launch_cmd" "$note" "$entry_kind"
  return "$exit_code"
}

function agent-sessions() {
  bash "$(_agent_sessions_script)" "$@"
}

function agent-restore-preview() {
  local agent_type="${1:-}"
  bash "$(_agent_sessions_script)" restore-command "$agent_type" "$PWD"
}

function agent-restore-here() {
  local agent_type="${1:-}"
  local restore_cmd

  restore_cmd="$(bash "$(_agent_sessions_script)" restore-command "$agent_type" "$PWD")" || {
    echo "No restorable agent session found for $PWD"
    return 1
  }

  eval "$restore_cmd"
}

function codexz() {
  _agent_sessions_run_with_tracking "codex" "codex" "codex" "$@"
}

function claudez() {
  _agent_sessions_run_with_tracking "claude" "claude" "claude" "$@"
}

function cursorz() {
  _agent_sessions_run_with_tracking "cursor-agent" "agent" "agent" "$@"
}

function agentz() {
  cursorz "$@"
}

function _terminal_saver_script() {
  echo "${DOTFILES_DIR:-$HOME/.dotfiles}/scripts/terminal-saver"
}

function _terminal_saver_capture_script() {
  echo "${DOTFILES_DIR:-$HOME/.dotfiles}/scripts/ghostty-capture-buffer"
}

function _terminal_saver_capture_mode() {
  local arg
  for arg in "$@"; do
    case "$arg" in
      --)
        break
        ;;
      -s|--screen)
        echo "screen"
        return 0
        ;;
      -b|--back|--scrollback)
        echo "scrollback"
        return 0
        ;;
      -f|--fill)
        return 1
        ;;
    esac
  done
  echo "screen"
  return 0
}

function _terminal_saver_is_info_mode() {
  local arg
  for arg in "$@"; do
    case "$arg" in
      -h|--help|--list)
        return 0
        ;;
      --)
        return 1
        ;;
    esac
  done
  return 1
}

function screensaver() {
  local script="$(_terminal_saver_script)"
  local capture_script="$(_terminal_saver_capture_script)"
  local capture_mode=""
  local capture_file=""
  if [[ ! -x "$script" ]]; then
    echo "missing script: $script"
    return 1
  fi

  capture_mode="$(_terminal_saver_capture_mode "$@")"

  if _terminal_saver_is_info_mode "$@"; then
    "$script" "$@"
    return $?
  fi

  if [[ -n "${ZELLIJ:-}" && -z "${TTE_SAVER_INLINE:-}" ]]; then
    if [[ -n "$capture_mode" && ! -x "$capture_script" ]]; then
      echo "missing script: $capture_script"
      return 1
    fi

    if [[ -n "$capture_mode" ]]; then
      capture_file="$(mktemp "${TMPDIR:-/tmp}/screensaver-capture.XXXXXX")" || return 1
      if ! "$capture_script" "$capture_mode" > "$capture_file"; then
        rm -f "$capture_file"
        return 1
      fi
    fi

    if [[ -n "$capture_file" ]]; then
      zellij run -f --close-on-exit --name "screensaver" --cwd "$PWD" --width 100% --height 100% --x 0 --y 0 --pinned true -- env TTE_SAVER_INLINE=1 TTE_SAVER_SOURCE_FILE="$capture_file" TTE_SAVER_SOURCE_FILE_DELETE=1 "$script" "$@"
      return $?
    fi

    zellij run -f --close-on-exit --name "screensaver" --cwd "$PWD" --width 100% --height 100% --x 0 --y 0 --pinned true -- env TTE_SAVER_INLINE=1 "$script" "$@"
    return $?
  fi

  "$script" "$@"
}

# jj <-> git sync helpers
jjpush() {
  jj git push "$@" || return $?
  local bookmark
  bookmark=$(jj bookmark list -r @ --no-pager 2>/dev/null | head -1 | awk '{print $1}' | tr -d ':')
  [ -n "$bookmark" ] && git checkout -f "$bookmark" 2>/dev/null
}

jjsync() {
  local bookmark
  bookmark=$(jj bookmark list -r @ --no-pager 2>/dev/null | head -1 | awk '{print $1}' | tr -d ':')
  if [ -n "$bookmark" ]; then
    git checkout -f "$bookmark" 2>/dev/null
    echo "git: on branch $bookmark"
  else
    echo "git: no bookmark on current jj change"
  fi
}
