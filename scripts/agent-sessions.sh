#!/usr/bin/env bash
set -euo pipefail

registry_dir() {
  if [[ -n "${AI_SESSION_REGISTRY_DIR:-}" ]]; then
    printf '%s\n' "$AI_SESSION_REGISTRY_DIR"
  else
    printf '%s\n' "${XDG_DATA_HOME:-$HOME/.local/share}/agent-sessions"
  fi
}

registry_file() {
  printf '%s/registry.json\n' "$(registry_dir)"
}

ensure_registry() {
  local dir file
  dir="$(registry_dir)"
  file="$(registry_file)"
  mkdir -p "$dir"
  [[ -f "$file" ]] || printf '[]\n' > "$file"
}

json_bool() {
  if [[ "$1" == "1" || "$1" == "true" ]]; then
    printf 'true'
  else
    printf 'false'
  fi
}

zellij_session_name() {
  if [[ -n "${ZELLIJ_SESSION_NAME:-}" ]]; then
    printf '%s\n' "$ZELLIJ_SESSION_NAME"
    return
  fi
  if [[ -n "${ZELLIJ:-}" ]]; then
    printf '%s\n' "${ZELLIJ##*/}"
  fi
}

zellij_layout_dump() {
  [[ -n "${ZELLIJ:-}" ]] || return 0
  zellij action dump-layout 2>/dev/null || true
}

zellij_current_tab_index() {
  local layout line idx=0
  layout="$(zellij_layout_dump)"
  [[ -n "$layout" ]] || return 0

  while IFS= read -r line; do
    [[ "$line" =~ ^[[:space:]]*tab([[:space:]]|\{) ]] || continue
    idx=$((idx + 1))
    [[ "$line" == *"focus=true"* ]] || continue
    printf '%s\n' "$idx"
    return 0
  done <<< "$layout"
}

zellij_current_tab_name() {
  local layout line idx=0
  layout="$(zellij_layout_dump)"
  [[ -n "$layout" ]] || return 0

  while IFS= read -r line; do
    [[ "$line" =~ ^[[:space:]]*tab([[:space:]]|\{) ]] || continue
    idx=$((idx + 1))
    [[ "$line" == *"focus=true"* ]] || continue
    if [[ "$line" =~ name=\"([^\"]+)\" ]]; then
      printf '%s\n' "${BASH_REMATCH[1]}"
    else
      printf 'tab-%s\n' "$idx"
    fi
    return 0
  done <<< "$layout"
}

zellij_current_pane_name() {
  local layout line
  layout="$(zellij_layout_dump)"
  [[ -n "$layout" ]] || return 0

  while IFS= read -r line; do
    [[ "$line" =~ ^[[:space:]]*pane([[:space:]]|\{) ]] || continue
    [[ "$line" == *"focus=true"* ]] || continue
    if [[ "$line" =~ name=\"([^\"]+)\" ]]; then
      printf '%s\n' "${BASH_REMATCH[1]}"
    fi
    return 0
  done <<< "$layout"
}

record_entry() {
  ensure_registry

  local launch_id="$1"
  local agent_type="$2"
  local status="$3"
  local resume_id="${4:-}"
  local started_at="${5:-0}"
  local completed_at="${6:-0}"
  local cwd="$7"
  local launch_cmd="$8"
  local note="${9:-}"
  local entry_kind="${10:-launch}"

  local file tmp terminal_program in_zellij zellij_session zellij_pane_id zellij_tab_name zellij_tab_index zellij_pane_name
  file="$(registry_file)"
  tmp="$(mktemp)"
  terminal_program="${TERM_PROGRAM:-${TERM:-unknown}}"
  in_zellij="$(json_bool "${ZELLIJ:+1}")"
  zellij_session="$(zellij_session_name || true)"
  zellij_pane_id="${ZELLIJ_PANE_ID:-}"
  zellij_tab_name="$(zellij_current_tab_name || true)"
  zellij_tab_index="$(zellij_current_tab_index || true)"
  zellij_pane_name="$(zellij_current_pane_name || true)"

  jq \
    --arg launch_id "$launch_id" \
    --arg agent_type "$agent_type" \
    --arg status "$status" \
    --arg resume_id "$resume_id" \
    --arg started_at "$started_at" \
    --arg completed_at "$completed_at" \
    --arg cwd "$cwd" \
    --arg launch_cmd "$launch_cmd" \
    --arg note "$note" \
    --arg entry_kind "$entry_kind" \
    --arg terminal_program "$terminal_program" \
    --arg zellij_session "$zellij_session" \
    --arg zellij_pane_id "$zellij_pane_id" \
    --arg zellij_tab_name "$zellij_tab_name" \
    --arg zellij_tab_index "$zellij_tab_index" \
    --arg zellij_pane_name "$zellij_pane_name" \
    --argjson in_zellij "$in_zellij" \
    '
      map(select(.launch_id != $launch_id)) +
      [{
        launch_id: $launch_id,
        agent_type: $agent_type,
        status: $status,
        resume_id: (if ($resume_id | length) > 0 then $resume_id else null end),
        started_at: ($started_at | tonumber),
        completed_at: (($completed_at | tonumber) | if . == 0 then null else . end),
        cwd: $cwd,
        launch_cmd: $launch_cmd,
        note: (if ($note | length) > 0 then $note else null end),
        entry_kind: $entry_kind,
        terminal: {
          program: $terminal_program,
          in_zellij: $in_zellij,
          zellij_session: (if ($zellij_session | length) > 0 then $zellij_session else null end),
          zellij_pane_id: (if ($zellij_pane_id | length) > 0 then $zellij_pane_id else null end),
          zellij_tab_name: (if ($zellij_tab_name | length) > 0 then $zellij_tab_name else null end),
          zellij_tab_index: (if ($zellij_tab_index | length) > 0 then ($zellij_tab_index | tonumber) else null end),
          zellij_pane_name: (if ($zellij_pane_name | length) > 0 then $zellij_pane_name else null end)
        }
      }]
    ' "$file" > "$tmp"
  mv "$tmp" "$file"
  compact_registry
}

lookup_entry() {
  ensure_registry
  local launch_id="$1"
  jq -c --arg launch_id "$launch_id" 'map(select(.launch_id == $launch_id)) | .[0] // empty' "$(registry_file)"
}

lookup_field() {
  local launch_id="$1"
  local field="$2"
  lookup_entry "$launch_id" | jq -r --arg field "$field" '.[$field] // empty'
}

update_entry_status() {
  ensure_registry

  local launch_id="$1"
  local status="$2"
  local resume_id="${3:-}"
  local note="${4:-}"
  local completed_at="${5:-}"
  local file tmp

  file="$(registry_file)"
  tmp="$(mktemp)"

  jq \
    --arg launch_id "$launch_id" \
    --arg status "$status" \
    --arg resume_id "$resume_id" \
    --arg note "$note" \
    --arg completed_at "$completed_at" \
    '
      map(
        if .launch_id == $launch_id then
          .status = $status |
          .resume_id = (if ($resume_id | length) > 0 then $resume_id else .resume_id end) |
          .note = (if ($note | length) > 0 then $note else .note end) |
          .completed_at = (
            if ($completed_at | length) > 0 then
              (($completed_at | tonumber) | if . == 0 then null else . end)
            else
              .completed_at
            end
          )
        else
          .
        end
      )
    ' "$file" > "$tmp"

  mv "$tmp" "$file"
  compact_registry
}

sqlite_escape() {
  printf "%s" "$1" | sed "s/'/''/g"
}

resolve_codex() {
  local cwd="$1"
  local started_at="${2:-0}"
  local db="$HOME/.codex/state_5.sqlite"
  [[ -f "$db" ]] || return 0

  local escaped_cwd
  escaped_cwd="$(sqlite_escape "$cwd")"

  sqlite3 "$db" "
    select id
    from threads
    where cwd = '$escaped_cwd'
      and updated_at >= ${started_at}
    order by updated_at desc
    limit 1;
  " | head -n 1
}

resolve_claude() {
  local cwd="$1"
  local started_at="${2:-0}"
  local projects_dir="$HOME/.claude/projects"
  [[ -d "$projects_dir" ]] || return 0

  local latest_file latest_mtime file mtime
  latest_file=""
  latest_mtime=0

  while IFS= read -r file; do
    [[ -n "$file" ]] || continue
    mtime="$(stat -f '%m' "$file" 2>/dev/null || printf '0')"
    if [[ "$mtime" -ge "$started_at" && "$mtime" -ge "$latest_mtime" ]]; then
      latest_file="$file"
      latest_mtime="$mtime"
    fi
  done < <(rg -l --fixed-strings "\"cwd\":\"$cwd\"" "$projects_dir" 2>/dev/null || true)

  if [[ -z "$latest_file" ]]; then
    while IFS= read -r file; do
      [[ -n "$file" ]] || continue
      mtime="$(stat -f '%m' "$file" 2>/dev/null || printf '0')"
      if [[ "$mtime" -ge "$latest_mtime" ]]; then
        latest_file="$file"
        latest_mtime="$mtime"
      fi
    done < <(rg -l --fixed-strings "\"cwd\":\"$cwd\"" "$projects_dir" 2>/dev/null || true)
  fi

  [[ -n "$latest_file" ]] || return 0
  head -n 20 "$latest_file" | jq -r '.sessionId // empty' 2>/dev/null | head -n 1
}

resolve_agent() {
  local cwd="$1"
  local started_at="${2:-0}"
  local projects_dir="$HOME/.cursor/projects"
  [[ -d "$projects_dir" ]] || return 0

  local resolved_cwd slug transcript_dir latest_file latest_mtime file mtime
  resolved_cwd="$(cd "$cwd" 2>/dev/null && pwd -P || printf '%s' "$cwd")"
  slug="$(printf '%s' "$resolved_cwd" | sed 's#^/##; s#[^A-Za-z0-9]#-#g; s#-\{2,\}#-#g; s#^-\|-$##g')"
  transcript_dir="$projects_dir/$slug/agent-transcripts"
  [[ -d "$transcript_dir" ]] || return 0

  latest_file=""
  latest_mtime=0

  while IFS= read -r file; do
    [[ -n "$file" ]] || continue
    mtime="$(stat -f '%m' "$file" 2>/dev/null || printf '0')"
    if [[ "$mtime" -ge "$started_at" && "$mtime" -ge "$latest_mtime" ]]; then
      latest_file="$file"
      latest_mtime="$mtime"
    fi
  done < <(find "$transcript_dir" -maxdepth 1 -type f | sort)

  if [[ -z "$latest_file" ]]; then
    while IFS= read -r file; do
      [[ -n "$file" ]] || continue
      mtime="$(stat -f '%m' "$file" 2>/dev/null || printf '0')"
      if [[ "$mtime" -ge "$latest_mtime" ]]; then
        latest_file="$file"
        latest_mtime="$mtime"
      fi
    done < <(find "$transcript_dir" -maxdepth 1 -type f | sort)
  fi

  [[ -n "$latest_file" ]] || return 0
  basename "$latest_file" | sed 's/\.[^.]*$//'
}

import_latest() {
  local agent_type="$1"
  local cwd="${2:-$PWD}"
  local launch_id resume_id
  launch_id="import-${agent_type}-$(date +%s)"

  case "$agent_type" in
    codex)
      resume_id="$(resolve_codex "$cwd" 0)"
      ;;
    claude)
      resume_id="$(resolve_claude "$cwd" 0)"
      ;;
    cursor-agent|agent)
      resume_id="$(resolve_agent "$cwd" 0)"
      agent_type="cursor-agent"
      ;;
    *)
      echo "unsupported agent type: $agent_type" >&2
      return 1
      ;;
  esac

  if [[ -n "$resume_id" ]]; then
    record_entry "$launch_id" "$agent_type" "imported" "$resume_id" "0" "0" "$cwd" "import-latest" "imported from local state"
    printf '%s\n' "$resume_id"
  else
    record_entry "$launch_id" "$agent_type" "unresolved" "" "0" "0" "$cwd" "import-latest" "no local resume id found"
  fi
}

refresh_active_entries() {
  ensure_registry

  local file
  file="$(registry_file)"

  while IFS=$'\t' read -r launch_id agent_type cwd started_at launch_cmd; do
    [[ -n "$launch_id" ]] || continue

    local resolver resolved_resume_id normalized_agent note
    case "$agent_type" in
      codex)
        resolver="codex"
        normalized_agent="codex"
        ;;
      claude)
        resolver="claude"
        normalized_agent="claude"
        ;;
      cursor-agent|agent)
        resolver="agent"
        normalized_agent="cursor-agent"
        ;;
      *)
        continue
        ;;
    esac

    resolved_resume_id="$(bash "$0" resolve "$resolver" "$cwd" "$started_at" 2>/dev/null || true)"
    if [[ -n "$resolved_resume_id" ]]; then
      note="resume id resolved from local state while session is still running"
      update_entry_status "$launch_id" "running" "$resolved_resume_id" "$note"
    fi
  done < <(
    jq -r '
      map(select(
        (.completed_at == null) and
        (.resume_id == null) and
        ((.entry_kind // "launch") != "probe")
      )) |
      .[] |
      [
        .launch_id,
        .agent_type,
        .cwd,
        (.started_at | tostring),
        (.launch_cmd // "")
      ] | @tsv
    ' "$file"
  )
}

compact_registry() {
  ensure_registry

  local file tmp
  file="$(registry_file)"
  tmp="$(mktemp)"

  jq '
    def active_entries:
      map(select(
        (.completed_at == null) and
        ((.entry_kind // "launch") != "probe")
      ));

    def resumable_entries:
      map(select(
        (.resume_id != null) and
        ((.entry_kind // "launch") != "probe")
      ))
      | sort_by(.started_at, (.completed_at // 0), .launch_id)
      | group_by([.agent_type, .resume_id])
      | map(last);

    ((active_entries + resumable_entries)
      | unique_by(.launch_id)
      | sort_by(.started_at, (.completed_at // 0), .launch_id))
  ' "$file" > "$tmp"

  mv "$tmp" "$file"
}

status_registry() {
  local show_all="${1:-0}"
  ensure_registry

  if [[ "$show_all" == "1" ]]; then
    jq -r '
      def effective_resume_id:
        .resume_id // (
          if .agent_type == "codex" and ((.launch_cmd // "") | test("^codex resume [^ ]+")) then
            ((.launch_cmd // "") | capture("^codex resume (?<id>[^ ]+)").id)
          elif .agent_type == "claude" and ((.launch_cmd // "") | test("(^| )(claude )?.*(--resume=|--resume |-r |--session-id=|--session-id )[^ ]+")) then
            if ((.launch_cmd // "") | test("--resume=")) then
              ((.launch_cmd // "") | capture(".*--resume=(?<id>[^ ]+)").id)
            elif ((.launch_cmd // "") | test("--session-id=")) then
              ((.launch_cmd // "") | capture(".*--session-id=(?<id>[^ ]+)").id)
            else
              ((.launch_cmd // "") | capture(".*(?:--resume|-r|--session-id) (?<id>[^ ]+)").id)
            end
          elif .agent_type == "cursor-agent" and ((.launch_cmd // "") | test("(^| )agent --resume(=| )[^ ]+")) then
            if ((.launch_cmd // "") | test("--resume=")) then
              ((.launch_cmd // "") | capture(".*--resume=(?<id>[^ ]+)").id)
            else
              ((.launch_cmd // "") | capture(".*--resume (?<id>[^ ]+)").id)
            end
          else
            null
          end
        );
      def effective_state:
        if (effective_resume_id != null) and (.completed_at == null) then
          "running"
        else
          (.status // "unknown")
        end;

      if length == 0 then
        "No agent sessions recorded."
      else
        (["agent", "status", "resume_id", "cwd", "terminal", "zellij_session", "tab", "pane", "kind"] | @tsv),
        (
          sort_by(.started_at, .launch_id) | reverse |
          .[] |
          [
            .agent_type,
            effective_state,
            (effective_resume_id // "-"),
            .cwd,
            (.terminal.program // "-"),
            (.terminal.zellij_session // "-"),
            (.terminal.zellij_tab_name // ((.terminal.zellij_tab_index // "-") | tostring)),
            (.terminal.zellij_pane_id // "-"),
            (.entry_kind // "launch")
          ] | @tsv
        )
      end
    ' "$(registry_file)" | column -t -s $'\t'
    return
  fi

  local rows=()
  mapfile -t rows < <(
    jq -r '
      def effective_resume_id:
        .resume_id // (
          if .agent_type == "codex" and ((.launch_cmd // "") | test("^codex resume [^ ]+")) then
            ((.launch_cmd // "") | capture("^codex resume (?<id>[^ ]+)").id)
          elif .agent_type == "claude" and ((.launch_cmd // "") | test("(^| )(claude )?.*(--resume=|--resume |-r |--session-id=|--session-id )[^ ]+")) then
            if ((.launch_cmd // "") | test("--resume=")) then
              ((.launch_cmd // "") | capture(".*--resume=(?<id>[^ ]+)").id)
            elif ((.launch_cmd // "") | test("--session-id=")) then
              ((.launch_cmd // "") | capture(".*--session-id=(?<id>[^ ]+)").id)
            else
              ((.launch_cmd // "") | capture(".*(?:--resume|-r|--session-id) (?<id>[^ ]+)").id)
            end
          elif .agent_type == "cursor-agent" and ((.launch_cmd // "") | test("(^| )agent --resume(=| )[^ ]+")) then
            if ((.launch_cmd // "") | test("--resume=")) then
              ((.launch_cmd // "") | capture(".*--resume=(?<id>[^ ]+)").id)
            else
              ((.launch_cmd // "") | capture(".*--resume (?<id>[^ ]+)").id)
            end
          else
            null
          end
        );
      def effective_state:
        if (effective_resume_id != null) and (.completed_at == null) then
          "running"
        else
          (.status // "unknown")
        end;

      map(select(
        (effective_resume_id != null) and
        ((.entry_kind // "launch") != "probe")
      )) |
      sort_by(.started_at, (.completed_at // 0), .launch_id) |
      map(. + { _effective_resume_id: effective_resume_id }) |
      group_by([.agent_type, ._effective_resume_id]) |
      map(last) |
      reverse |
      .[] |
      [
        .agent_type,
        ._effective_resume_id,
        .cwd,
        (.terminal.program // "-"),
        (.terminal.zellij_session // "-"),
        (.terminal.zellij_tab_name // ((.terminal.zellij_tab_index // "-") | tostring)),
        (.terminal.zellij_pane_id // "-"),
        effective_state
      ] | @tsv
    ' "$(registry_file)"
  )

  if [[ ${#rows[@]} -eq 0 ]]; then
    echo "No stored sessions found."
    return
  fi

  local row agent_type resume_id cwd terminal_program zellij_session zellij_tab pane state display_cwd repo_name
  for row in "${rows[@]}"; do
    IFS=$'\t' read -r agent_type resume_id cwd terminal_program zellij_session zellij_tab pane state <<< "$row"
    display_cwd="${cwd/#$HOME/~}"
    repo_name="$(basename "$cwd")"
    printf '%s  %s  [%s]\n' "$agent_type" "$repo_name" "$state"
    printf '  cwd: %s\n' "$display_cwd"
    if [[ "$zellij_session" != "-" ]]; then
      printf '  zellij: %s / %s / pane %s\n' "$zellij_session" "$zellij_tab" "$pane"
    else
      printf '  terminal: %s\n' "$terminal_program"
    fi
    printf '  resume: %s\n' "$resume_id"
    printf '\n'
  done
}

usage() {
  cat <<'EOF'
Usage: agent-sessions.sh <command> [args]

Commands:
  ensure
  status [--all]
  record <launch_id> <agent_type> <status> <resume_id> <started_at> <completed_at> <cwd> <launch_cmd> [note] [entry_kind]
  resolve <codex|claude|agent> <cwd> [started_at]
  import-latest <codex|claude|agent> [cwd]
  best-match [agent_type] [cwd]
  restore-command [agent_type] [cwd]
  lookup <launch_id>
  lookup-field <launch_id> <field>
EOF
}

best_match() {
  ensure_registry

  local agent_type="${1:-}"
  local cwd="${2:-$PWD}"
  local active_only="${3:-0}"
  local zellij_session=""
  local zellij_tab_name=""
  local zellij_tab_index=""
  local zellij_pane_id="${ZELLIJ_PANE_ID:-}"
  local zellij_pane_name=""

  if [[ -n "${ZELLIJ:-}" ]]; then
    zellij_session="$(zellij_session_name || true)"
    zellij_tab_name="$(zellij_current_tab_name || true)"
    zellij_tab_index="$(zellij_current_tab_index || true)"
    zellij_pane_name="$(zellij_current_pane_name || true)"
  fi

  jq -c \
    --arg cwd "$cwd" \
    --arg agent_type "$agent_type" \
    --arg zellij_session "$zellij_session" \
    --arg zellij_tab_name "$zellij_tab_name" \
    --arg zellij_tab_index "$zellij_tab_index" \
    --arg zellij_pane_id "$zellij_pane_id" \
    --arg zellij_pane_name "$zellij_pane_name" \
    --argjson active_only "$active_only" '
    def effective_resume_id:
      .resume_id // (
        if .agent_type == "codex" and ((.launch_cmd // "") | test("^codex resume [^ ]+")) then
          ((.launch_cmd // "") | capture("^codex resume (?<id>[^ ]+)").id)
        elif .agent_type == "claude" and ((.launch_cmd // "") | test("(^| )(claude )?.*(--resume=|--resume |-r |--session-id=|--session-id )[^ ]+")) then
          if ((.launch_cmd // "") | test("--resume=")) then
            ((.launch_cmd // "") | capture(".*--resume=(?<id>[^ ]+)").id)
          elif ((.launch_cmd // "") | test("--session-id=")) then
            ((.launch_cmd // "") | capture(".*--session-id=(?<id>[^ ]+)").id)
          else
            ((.launch_cmd // "") | capture(".*(?:--resume|-r|--session-id) (?<id>[^ ]+)").id)
          end
        elif .agent_type == "cursor-agent" and ((.launch_cmd // "") | test("(^| )agent --resume(=| )[^ ]+")) then
          if ((.launch_cmd // "") | test("--resume=")) then
            ((.launch_cmd // "") | capture(".*--resume=(?<id>[^ ]+)").id)
          else
            ((.launch_cmd // "") | capture(".*--resume (?<id>[^ ]+)").id)
          end
        else
          null
        end
      );

    map(select(
      (effective_resume_id != null) and
      ((.entry_kind // "launch") != "probe") and
      (($active_only | not) or (.completed_at == null)) and
      (.cwd == $cwd) and
      (($agent_type == "") or (.agent_type == $agent_type))
    )) |
    map(
      . + {
        _effective_resume_id: effective_resume_id,
        _score:
          (if .cwd == $cwd then 100 else 0 end) +
          (if ($zellij_session != "" and .terminal.zellij_session == $zellij_session) then 20 else 0 end) +
          (if ($zellij_tab_name != "" and .terminal.zellij_tab_name == $zellij_tab_name) then 30 else 0 end) +
          (if ($zellij_tab_index != "" and ((.terminal.zellij_tab_index // -1) | tostring) == $zellij_tab_index) then 10 else 0 end) +
          (if ($zellij_pane_id != "" and .terminal.zellij_pane_id == $zellij_pane_id) then 15 else 0 end) +
          (if ($zellij_pane_name != "" and .terminal.zellij_pane_name == $zellij_pane_name) then 10 else 0 end) +
          (if ($agent_type != "" and .agent_type == $agent_type) then 10 else 0 end)
      }
    ) |
    sort_by(._score, (.completed_at // 0), .started_at) |
    reverse |
    if length == 0 then
      empty
    else
      . as $matches |
      ($matches[0]._score) as $top_score |
      ($matches | map(select(._score == $top_score))) as $top_matches |
      if ($top_matches | length) == 1 then
        $top_matches[0]
      else
        empty
      end
    end
  ' "$(registry_file)"
}

restore_command() {
  local agent_type="${1:-}"
  local cwd="${2:-$PWD}"
  local match resume_id resolved_agent

  match="$(best_match "$agent_type" "$cwd")"
  [[ -n "$match" ]] || return 1

  resume_id="$(printf '%s\n' "$match" | jq -r '.resume_id')"
  if [[ -z "$resume_id" || "$resume_id" == "null" ]]; then
    resume_id="$(printf '%s\n' "$match" | jq -r '._effective_resume_id // empty')"
  fi
  resolved_agent="$(printf '%s\n' "$match" | jq -r '.agent_type')"

  case "$resolved_agent" in
    codex)
      printf 'cd %q && codex resume %q\n' "$cwd" "$resume_id"
      ;;
    claude)
      printf 'cd %q && claude --resume %q\n' "$cwd" "$resume_id"
      ;;
    cursor-agent)
      printf 'cd %q && agent --resume %q\n' "$cwd" "$resume_id"
      ;;
    *)
      echo "unsupported agent type: $resolved_agent" >&2
      return 1
      ;;
  esac
}

main() {
  local cmd="${1:-}"
  case "$cmd" in
    ensure)
      ensure_registry
      ;;
    status)
      if [[ "${2:-}" == "--all" ]]; then
        status_registry 1
      else
        status_registry 0
      fi
      ;;
    record)
      shift
      record_entry "$@"
      ;;
    resolve)
      local agent_type="${2:-}" cwd="${3:-$PWD}" started_at="${4:-0}"
      case "$agent_type" in
        codex) resolve_codex "$cwd" "$started_at" ;;
        claude) resolve_claude "$cwd" "$started_at" ;;
        agent|cursor-agent) resolve_agent "$cwd" "$started_at" ;;
        *) echo "unsupported agent type: $agent_type" >&2; return 1 ;;
      esac
      ;;
    import-latest)
      import_latest "${2:-}" "${3:-$PWD}"
      ;;
    best-match)
      best_match "${2:-}" "${3:-$PWD}" "0"
      ;;
    best-running-match)
      best_match "${2:-}" "${3:-$PWD}" "1"
      ;;
    restore-command)
      restore_command "${2:-}" "${3:-$PWD}"
      ;;
    lookup)
      lookup_entry "${2:-}"
      ;;
    lookup-field)
      lookup_field "${2:-}" "${3:-}"
      ;;
    ""|-h|--help|help)
      usage
      ;;
    *)
      echo "unknown command: $cmd" >&2
      usage >&2
      return 1
      ;;
  esac
}

main "$@"
