# Shared functions — loaded on all machines

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
