#!/usr/bin/env bash
# PreToolUse hook for the Bash tool.
# Reads the tool-call JSON from stdin and blocks dangerous commands.
# Exit code 2 blocks the call and feeds stderr back to Claude; 0 allows it.
set -euo pipefail

input="$(cat)"
cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty')"

# Nothing to validate.
[ -z "$cmd" ] && exit 0

block() {
  echo "Blocked by validate-bash.sh: $1" >&2
  exit 2
}

# Destructive file removal (rm with recursive+force flags in any order).
if printf '%s' "$cmd" | grep -Eq '(^|[;&|[:space:]])rm[[:space:]]+(-[a-zA-Z]*[rR][a-zA-Z]*[fF]|-[a-zA-Z]*[fF][a-zA-Z]*[rR]|--recursive|--force)'; then
  block "recursive/forced rm is not allowed"
fi

# History-destroying git operations.
if printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+push[^;&|]*([[:space:]]--force([[:space:]]|$)|[[:space:]]--force-with-lease|[[:space:]]-f([[:space:]]|$))'; then
  block "force push is not allowed"
fi
printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+reset[[:space:]]+--hard' && block "git reset --hard is not allowed"
printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+clean[[:space:]]+-[a-zA-Z]*f' && block "git clean -f is not allowed"
printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+branch[[:space:]]+-D' && block "git branch -D is not allowed"

# Remote code execution via pipe-to-shell.
printf '%s' "$cmd" | grep -Eq '(curl|wget)[^|]*\|[[:space:]]*(sudo[[:space:]]+)?(ba|z)?sh' && block "piping downloads into a shell is not allowed"

# Privilege escalation and disk-level commands.
printf '%s' "$cmd" | grep -Eq '(^|[;&|[:space:]])sudo[[:space:]]' && block "sudo is not allowed"
printf '%s' "$cmd" | grep -Eq '(^|[;&|[:space:]])(mkfs|dd[[:space:]]+if=|chmod[[:space:]]+-R[[:space:]]+777)' && block "disk/permission-destroying command"

# Reading or printing secrets.
if printf '%s' "$cmd" | grep -Eq '(cat|less|more|head|tail|cp|base64)[[:space:]][^;&|]*(\.env|\.jks|\.keystore|key\.properties|google-services\.json|GoogleService-Info\.plist|config/(dev|staging|prod)\.json)'; then
  block "reading secret files is not allowed"
fi

# Publishing the package by accident.
printf '%s' "$cmd" | grep -Eq 'flutter[[:space:]]+pub[[:space:]]+publish|dart[[:space:]]+pub[[:space:]]+publish' && block "pub publish is not allowed"

exit 0
