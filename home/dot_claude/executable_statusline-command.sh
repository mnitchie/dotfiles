#!/bin/sh
# Claude Code status line: model | repo or directory | context used | session cost | 5h and 7d quota.
input="$(cat)"
model="$(printf '%s' "${input}" | jq -r '.model.display_name // "?"')"
dir="$(printf '%s' "${input}" | jq -r '.workspace.current_dir // .cwd // empty')"
context="$(printf '%s' "${input}" | jq -r '.context_window.used_percentage // empty')"
cost="$(printf '%s' "${input}" | jq -r '.cost.total_cost_usd // 0')"
# rate_limits exists only for Pro/Max subscribers after the first API response; each window may be absent.
five_hour="$(printf '%s' "${input}" | jq -r '.rate_limits.five_hour.used_percentage // empty')"
seven_day="$(printf '%s' "${input}" | jq -r '.rate_limits.seven_day.used_percentage // empty')"

name="$(basename "$(git -C "${dir:-.}" rev-parse --show-toplevel 2>/dev/null || printf '%s' "${dir:-.}")")"
if [ -n "${context}" ]; then
  context="$(printf '%.0f%%' "${context}")"
else
  context="--"
fi
line="$(printf '%s | %s | ctx %s | $%.2f' "${model}" "${name}" "${context}" "${cost}")"
[ -n "${five_hour}" ] && line="${line} | 5h $(printf '%.0f%%' "${five_hour}")"
[ -n "${seven_day}" ] && line="${line} | 7d $(printf '%.0f%%' "${seven_day}")"
printf '%s' "${line}"
