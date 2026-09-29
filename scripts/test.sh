#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
chezmoi="${repo_root}/.bin/chezmoi"

keep=0
if [[ $# -gt 0 ]]; then
  if [[ $# -eq 1 && "$1" == "--keep" ]]; then
    keep=1
  else
    echo "usage: scripts/test.sh [--keep]" >&2
    exit 2
  fi
fi

for cmd in zsh shellcheck git; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "missing ${cmd}; run scripts/install-test-tools.sh" >&2
    exit 1
  fi
done
if [[ ! -x "$chezmoi" ]]; then
  echo "missing ${chezmoi}; run scripts/install-test-tools.sh" >&2
  exit 1
fi

shellcheck \
  "${repo_root}/scripts/install-test-tools.sh" \
  "${repo_root}/scripts/test.sh"

# A prefix keeps these dirs recognizable; TMPDIR may not be /tmp (macOS CI).
tmp="$(mktemp -d "${TMPDIR:-/tmp}/chezmoi-test.XXXXXX")"
if [[ ! -d "$tmp" || "$(basename "$tmp")" != chezmoi-test.* || "$tmp" == "$repo_root" || "$tmp" == "$repo_root"/* ]]; then
  echo "refusing to use temp dir: ${tmp}" >&2
  exit 1
fi
# --keep prints the directory and leaves it; every other exit removes it.
trap '[[ "$keep" -eq 1 ]] || rm -rf -- "$tmp"' EXIT
if [[ "$keep" -eq 1 ]]; then
  printf 'temp dir: %s\n' "$tmp"
fi

mkdir -p \
  "$tmp/cache" \
  "$tmp/xdg/cache" \
  "$tmp/xdg/config" \
  "$tmp/xdg/data" \
  "$tmp/xdg/state"

# The work-secrets test points chezmoi at an absolute stub via onepassword.command.
# Anything else that looks up `op` on PATH must fail instead of calling a real CLI.
op_guard_dir="$tmp/op-guard"
mkdir -p "$op_guard_dir"
cat >"$op_guard_dir/op" <<'EOF'
#!/usr/bin/env bash
printf 'refusing to invoke op from PATH: %s\n' "$*" >&2
exit 99
EOF
chmod +x "$op_guard_dir/op"
export PATH="${op_guard_dir}:${PATH}"

# chezmoi: warning: config file template has changed, run chezmoi init to regenerate config file
# Printed when --config points at a profile while home/.chezmoi.toml.tmpl exists.
config_template_warning="config file template has changed"

run_chezmoi() {
  local stdout_file stderr_file filtered_file status
  stdout_file="$tmp/chezmoi-stdout"
  stderr_file="$tmp/chezmoi-stderr"
  filtered_file="$tmp/chezmoi-stderr-filtered"
  status=0
  # chezmoi's cache, config, and state default to directories under $HOME.
  env \
    XDG_CACHE_HOME="$tmp/xdg/cache" \
    XDG_CONFIG_HOME="$tmp/xdg/config" \
    XDG_DATA_HOME="$tmp/xdg/data" \
    XDG_STATE_HOME="$tmp/xdg/state" \
    "$chezmoi" \
    --cache "$tmp/cache" \
    --no-tty \
    "$@" >"$stdout_file" 2>"$stderr_file" || status=$?
  grep -F -v "$config_template_warning" "$stderr_file" >"$filtered_file" || true
  if [[ "$status" -ne 0 ]]; then
    cat "$stderr_file" >&2
    if [[ -s "$stdout_file" ]]; then
      cat "$stdout_file" >&2
    fi
    return "$status"
  fi
  if [[ -s "$filtered_file" ]]; then
    cat "$filtered_file" >&2
    return 1
  fi
  cat "$stdout_file"
}

# Third argument of promptBoolOnce / promptStringOnce, one prompt per line.
template_prompt_texts() {
  local matches rc
  rc=0
  matches="$(grep -E -o 'prompt(Bool|String)Once[^"]*"[^"]*"[^"]*"[^"]*"' "$1")" || rc=$?
  if [[ "$rc" -eq 1 ]]; then
    return 0
  fi
  if [[ "$rc" -ne 0 ]]; then
    echo "failed to read prompts from ${1}" >&2
    return 1
  fi
  printf '%s\n' "$matches" | sed 's/.*"\([^"]*\)"$/\1/'
}

# tests/init-answers lines are single argv elements, e.g.
# --promptBool=Headless Linux (no 1Password app)=true
answer_prompt_text() {
  local line="$1" rest
  case "$line" in
    --promptBool=* | --promptString=*)
      rest="${line#*=}"
      ;;
    --promptBool\ * | --promptString\ *)
      rest="${line#* }"
      ;;
    *)
      return 1
      ;;
  esac
  if [[ "$rest" != *=* ]]; then
    return 1
  fi
  printf '%s\n' "${rest%=*}"
}

prompt_args=()
load_prompt_args() {
  local answers="$repo_root/tests/init-answers"
  local line prompt
  prompt_args=()
  if [[ ! -f "$answers" ]]; then
    echo "missing ${answers}" >&2
    return 1
  fi
  while IFS= read -r line || [[ -n "$line" ]]; do
    case "$line" in
      '' | '#'*) continue ;;
    esac
    if ! prompt="$(answer_prompt_text "$line")"; then
      echo "bad prompt answer line: ${line}" >&2
      return 1
    fi
    if [[ -z "$prompt" ]]; then
      echo "prompt answer has an empty prompt: ${line}" >&2
      return 1
    fi
    prompt_args+=("$line")
  done <"$answers"
  if [[ ${#prompt_args[@]} -eq 0 ]]; then
    echo "no prompt answers in ${answers}" >&2
    return 1
  fi
}

# chezmoi returns false for an unknown promptBool, so a new prompt must fail here.
template_prompts_covered() {
  local template="$1"
  local answers="$repo_root/tests/init-answers"
  local prompt line covered missing
  missing=0
  while IFS= read -r prompt; do
    [[ -n "$prompt" ]] || continue
    covered=0
    while IFS= read -r line || [[ -n "$line" ]]; do
      case "$line" in
        '' | '#'*) continue ;;
      esac
      if [[ "$(answer_prompt_text "$line")" == "$prompt" ]]; then
        covered=1
        break
      fi
    done <"$answers"
    if [[ "$covered" -eq 0 ]]; then
      echo "init template prompt has no answer: ${prompt}" >&2
      missing=1
    fi
  done < <(template_prompt_texts "$template")
  return "$missing"
}

data_keys() {
  awk '
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*\[data\][[:space:]]*$/ { in_data = 1; next }
    /^[[:space:]]*\[/ { in_data = 0; next }
    in_data {
      line = $0
      sub(/^[[:space:]]+/, "", line)
      sub(/[[:space:]]+$/, "", line)
      if (line == "" || substr(line, 1, 1) == "#") next
      if (index(line, "=") == 0) next
      sub(/[[:space:]]*=.*/, "", line)
      if (substr(line, 1, 1) == "\"") {
        len = length(line)
        if (substr(line, len, 1) == "\"") {
          line = substr(line, 2, len - 2)
        }
      }
      if (line ~ /^[A-Za-z_][A-Za-z0-9_]*$/) print line
    }
  ' "$1" | LC_ALL=C sort -u
}

profile_only_data() {
  awk '
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*$/ { next }
    /^[[:space:]]*\[data\][[:space:]]*$/ { in_data = 1; next }
    /^[[:space:]]*\[/ {
      in_data = 0
      print NR ": " $0
      next
    }
    in_data && /^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*[[:space:]]*=/ { next }
    { print NR ": " $0 }
  ' "$1"
}

is_blank() {
  local stripped
  stripped="$(tr -d '[:space:]' < "$1")"
  [[ -z "$stripped" ]]
}

# GNU stat -c %a; macOS stat -f %OLp. Prints the mode without a leading zero.
file_mode() {
  local mode
  if mode="$(stat -c %a "$1" 2>/dev/null)"; then
    printf '%s\n' "$mode"
    return 0
  fi
  stat -f %OLp "$1"
}

snapshot_repo() {
  find "$repo_root" \
    \( -path "$repo_root/.git" -o -path "$repo_root/.bin" \) -prune \
    -o -print | LC_ALL=C sort
}

home_chezmoi_paths=(
  "$HOME/.cache/chezmoi"
  "$HOME/.config/chezmoi"
  "$HOME/.local/share/chezmoi"
  "$HOME/.local/state/chezmoi"
)
# chezmoi rewrites its state database in place, so a path list would miss that.
snapshot_home_chezmoi() {
  local path
  local -a hash_cmd
  if command -v sha256sum >/dev/null 2>&1; then
    hash_cmd=(sha256sum)
  elif command -v shasum >/dev/null 2>&1; then
    hash_cmd=(shasum -a 256)
  else
    echo "sha256sum or shasum is required to snapshot chezmoi state" >&2
    return 1
  fi
  for path in "${home_chezmoi_paths[@]}"; do
    if [[ -e "$path" ]]; then
      find "$path" -type f -exec "${hash_cmd[@]}" {} +
    fi
  done | LC_ALL=C sort
}

test_profile() {
  local name="$1"
  local profile="$repo_root/tests/profiles/${name}.toml"
  local out="$tmp/${name}"
  local scripts_out="$tmp/${name}.scripts"
  local state="$tmp/${name}.state"
  local exclude="scripts,externals"
  local failed_checks=0
  local script rel rendered
  local zsh_file git_file git_base
  local secret_re secret_out secret_rc

  if [[ "${TEST_EXTERNALS:-}" == "1" ]]; then
    exclude="scripts"
  fi

  mkdir -p "$out" "$scripts_out"

  if ! run_chezmoi \
    --source "$repo_root" \
    --destination "$out" \
    --config "$profile" \
    --persistent-state "$state" \
    apply --exclude="$exclude" --force
  then
    echo "${name}: chezmoi apply failed" >&2
    return 1
  fi

  if [[ -e "$out/README.md" || -e "$out/scripts/test.sh" ]]; then
    echo "${name}: rendered repo files; .chezmoiroot was not applied" >&2
    return 1
  fi

  if [[ -d "$repo_root/home/.chezmoiscripts" ]]; then
    while IFS= read -r -d '' script; do
      rel="${script#"$repo_root/home/.chezmoiscripts"/}"
      rel="${rel%.tmpl}"
      rendered="${scripts_out}/${rel}"
      mkdir -p "$(dirname "$rendered")"
      if ! run_chezmoi \
        --source "$repo_root" \
        --config "$profile" \
        --destination "$out" \
        --persistent-state "$state" \
        execute-template <"$script" >"$rendered"
      then
        echo "${name}: execute-template failed for ${rel}" >&2
        failed_checks=1
        continue
      fi
      if is_blank "$rendered"; then
        continue
      fi
      if ! shellcheck "$rendered" >&2; then
        echo "${name}: shellcheck failed for ${rel}" >&2
        failed_checks=1
      fi
    done < <(find "$repo_root/home/.chezmoiscripts" -type f -print0)
  fi

  while IFS= read -r -d '' zsh_file; do
    case "$(basename "$zsh_file")" in
      .zshenv | .zprofile | .zshrc | *.zsh)
        if ! zsh -n "$zsh_file" >&2; then
          echo "${name}: zsh -n failed for ${zsh_file#"$out"/}" >&2
          failed_checks=1
        fi
        ;;
    esac
  done < <(find "$out" -type f -print0)

  if [[ -d "$out/.config/git" ]]; then
    while IFS= read -r -d '' git_file; do
      git_base="$(basename "$git_file")"
      if [[ "$git_base" == "ignore" ]]; then
        continue
      fi
      if ! git config --file "$git_file" --list >/dev/null; then
        echo "${name}: git config --file failed for ${git_file#"$out"/}" >&2
        failed_checks=1
      fi
    done < <(find "$out/.config/git" -type f -print0)
  fi

  secret_re='BEGIN .*PRIVATE KEY|ghp_|gho_|github_pat_|AKIA[0-9A-Z]{16}|oauth_token'
  secret_rc=0
  secret_out="$(grep -R -n -E -e "$secret_re" -- "$out" "$scripts_out")" || secret_rc=$?
  if [[ "$secret_rc" -eq 0 ]]; then
    printf '%s\n' "$secret_out" >&2
    echo "${name}: secret pattern in rendered files" >&2
    failed_checks=1
  elif [[ "$secret_rc" -gt 1 ]]; then
    printf '%s\n' "$secret_out" >&2
    echo "${name}: secret scan failed" >&2
    failed_checks=1
  fi

  return "$failed_checks"
}

test_work_secrets() {
  local failed_checks=0
  local name out secrets_stub secrets_out secrets_state
  local op_stub_dir op_stub secrets_tpl rendered
  local empty_out expected_log mode zsh_out

  for name in "${profile_names[@]}"; do
    out="$tmp/${name}"
    if [[ -f "$out/.config/zsh/conf.d/work-secrets.zsh" ]]; then
      echo "work-secrets: ${name} profile rendered work-secrets.zsh unexpectedly" >&2
      failed_checks=1
    fi
  done

  secrets_tpl="$repo_root/home/dot_config/zsh/conf.d/private_work-secrets.zsh.tmpl"
  empty_out="$tmp/work-secrets-empty.zsh"
  mkdir -p "$tmp/empty-dest"
  # darwin is a work machine with an empty account: the template must render
  # nothing and must not look up `op` (the PATH guard fails the command if it does).
  if ! run_chezmoi \
    --source "$repo_root" \
    --config "$repo_root/tests/profiles/darwin.toml" \
    --destination "$tmp/empty-dest" \
    --persistent-state "$tmp/empty.state" \
    execute-template <"$secrets_tpl" >"$empty_out"
  then
    echo "work-secrets: empty opWorkAccount execute-template failed" >&2
    failed_checks=1
  elif [[ -s "$empty_out" ]]; then
    echo "work-secrets: empty opWorkAccount rendered output" >&2
    failed_checks=1
  fi

  op_stub_dir="$tmp/op-stub"
  mkdir -p "$op_stub_dir"
  op_stub="$op_stub_dir/op"
  cat >"$op_stub" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
log_file="${OP_STUB_LOG:-}"
if [[ -n "$log_file" ]]; then
  printf '%s\n' "$*" >>"$log_file"
fi
case "${1:-}" in
  --version)
    printf '%s\n' '2.30.0'
    ;;
  account)
    shift
    if [[ "${1:-}" != "list" ]]; then
      printf 'unexpected op account command: %s\n' "$*" >&2
      exit 1
    fi
    printf '%s' '[{"url":"employee.1password.com","email":"stub@example.com","user_uuid":"stub-user-uuid","account_uuid":"stub-account-uuid"}]'
    ;;
  read)
    shift
    ref=""
    account=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --no-newline)
          shift
          ;;
        --account)
          if [[ $# -lt 2 ]]; then
            printf 'op read --account missing value\n' >&2
            exit 1
          fi
          account="$2"
          shift 2
          ;;
        --session)
          printf 'op read must not receive --session when prompt=false\n' >&2
          exit 1
          ;;
        *)
          if [[ -n "$ref" ]]; then
            printf 'unexpected op read arg: %s\n' "$1" >&2
            exit 1
          fi
          ref="$1"
          shift
          ;;
      esac
    done
    if [[ "$account" != "stub-account-uuid" ]]; then
      printf 'unexpected --account: %s\n' "$account" >&2
      exit 1
    fi
    case "$ref" in
      op://Private/Gemfury/credential)
        printf '%s' "stub'token"
        ;;
      op://Private/Gemfury/org)
        printf '%s' 'stub-org'
        ;;
      op://Private/Cloudflare/credential)
        printf '%s' 'stub-cf'
        ;;
      'op://Private/Google Stitch/credential')
        printf '%s' 'stub-stitch'
        ;;
      *)
        printf 'unexpected ref: %s\n' "$ref" >&2
        exit 1
        ;;
    esac
    ;;
  *)
    printf 'unexpected op stub invocation: %s\n' "$*" >&2
    exit 1
    ;;
esac
STUB
  chmod +x "$op_stub"
  if ! shellcheck "$op_stub"; then
    echo "work-secrets: shellcheck failed for op stub" >&2
    failed_checks=1
  fi

  secrets_stub="$tmp/secrets-stub.toml"
  sed 's/^opWorkAccount = ""/opWorkAccount = "employee.1password.com"/' \
    "$repo_root/tests/profiles/darwin.toml" >"$secrets_stub"
  if ! grep -q '^opWorkAccount = "employee.1password.com"$' "$secrets_stub"; then
    echo "work-secrets: failed to set opWorkAccount in stub config" >&2
    return 1
  fi
  {
    printf '\n[onepassword]\n'
    printf 'command = "%s"\n' "$op_stub"
    printf 'prompt = false\n'
  } >>"$secrets_stub"

  secrets_out="$tmp/secrets-out"
  secrets_state="$tmp/secrets.state"
  mkdir -p "$secrets_out"
  rendered="$secrets_out/.config/zsh/conf.d/work-secrets.zsh"
  # Pass the log path only to this chezmoi run. run_chezmoi inherits the
  # environment, and this function is not the end of the script.
  OP_STUB_LOG="$tmp/op-stub.log"
  export OP_STUB_LOG
  : >"$OP_STUB_LOG"
  if ! run_chezmoi \
    --source "$repo_root" \
    --config "$secrets_stub" \
    --destination "$secrets_out" \
    --persistent-state "$secrets_state" \
    apply --exclude=scripts,externals --force
  then
    echo "work-secrets: apply failed" >&2
    failed_checks=1
    unset OP_STUB_LOG
    return "$failed_checks"
  fi

  expected_log="$tmp/op-stub-expected.log"
  cat >"$expected_log" <<'EOF'
account list --format=json
read --no-newline op://Private/Gemfury/credential --account stub-account-uuid
read --no-newline op://Private/Gemfury/org --account stub-account-uuid
read --no-newline op://Private/Cloudflare/credential --account stub-account-uuid
read --no-newline op://Private/Google Stitch/credential --account stub-account-uuid
EOF
  if ! cmp -s "$expected_log" "$OP_STUB_LOG"; then
    echo "work-secrets: unexpected op invocations" >&2
    diff -u "$expected_log" "$OP_STUB_LOG" >&2 || true
    failed_checks=1
  fi
  unset OP_STUB_LOG

  if [[ ! -f "$rendered" ]]; then
    echo "work-secrets: apply did not create work-secrets.zsh" >&2
    failed_checks=1
    return "$failed_checks"
  fi
  if ! mode="$(file_mode "$rendered")"; then
    echo "work-secrets: stat failed for work-secrets.zsh" >&2
    failed_checks=1
  elif [[ "$mode" != "600" ]]; then
    echo "work-secrets: mode is ${mode}, want 600" >&2
    failed_checks=1
  fi
  if [[ "$(tail -c 1 "$rendered" | wc -l)" -eq 0 ]]; then
    echo "work-secrets: rendered file has no trailing newline" >&2
    failed_checks=1
  fi
  if grep -q '^$' "$rendered"; then
    echo "work-secrets: rendered file has a blank line" >&2
    failed_checks=1
  fi
  if ! zsh -n "$rendered" >&2; then
    echo "work-secrets: zsh -n failed" >&2
    failed_checks=1
  fi
  if ! zsh_out="$(zsh -f -c 'source "$1"; print -r -- "$FURY_AUTH" "$UV_INDEX_GEMFURY_USERNAME" "$UV_INDEX_GEMFURY_PASSWORD" "$PIP_EXTRA_INDEX_URL" "$CLOUDFLARE_API_TOKEN" "$GOOGLE_STITCH_API_KEY"' _ "$rendered")"; then
    echo "work-secrets: sourcing rendered file failed" >&2
    failed_checks=1
    return "$failed_checks"
  fi
  if [[ "$zsh_out" != "stub'token stub'token NOPASS https://stub'token:@pypi.fury.io/stub-org/ stub-cf stub-stitch" ]]; then
    echo "work-secrets: unexpected env vars: ${zsh_out}" >&2
    failed_checks=1
  fi

  return "$failed_checks"
}

if ! load_prompt_args; then
  exit 1
fi

repo_before="$tmp/repo-before"
home_before="$tmp/home-before"
snapshot_repo >"$repo_before"
snapshot_home_chezmoi >"$home_before"

failed=0
profile_names=(darwin linux-server linux-desktop wsl)
expected_keys=""
ref_profile=""
for name in "${profile_names[@]}"; do
  profile="${repo_root}/tests/profiles/${name}.toml"
  if [[ -f "$profile" ]]; then
    expected_keys="$(data_keys "$profile")"
    ref_profile="$name"
    break
  fi
done
for name in "${profile_names[@]}"; do
  profile="${repo_root}/tests/profiles/${name}.toml"
  profile_ok=0
  if [[ ! -f "$profile" ]]; then
    echo "missing ${profile}" >&2
    profile_ok=1
  else
    extra="$(profile_only_data "$profile")"
    if [[ -n "$extra" ]]; then
      echo "${name}: profile has lines outside [data]" >&2
      printf '%s\n' "$extra" >&2
      profile_ok=1
    fi
    got="$(data_keys "$profile")"
    if [[ "$name" != "$ref_profile" && "$got" != "$expected_keys" ]]; then
      echo "${name}: [data] keys differ from ${ref_profile}" >&2
      diff -u <(printf '%s\n' "$expected_keys") <(printf '%s\n' "$got") >&2 || true
      profile_ok=1
    fi
    if ! test_profile "$name"; then
      profile_ok=1
    fi
  fi
  if [[ "$profile_ok" -eq 0 ]]; then
    echo "${name} pass"
  else
    echo "${name} fail"
    failed=1
  fi
done

if test_work_secrets; then
  echo "work-secrets pass"
else
  echo "work-secrets fail"
  failed=1
fi

template="${repo_root}/home/.chezmoi.toml.tmpl"
if [[ ! -f "$template" ]]; then
  echo "notice: home/.chezmoi.toml.tmpl does not exist; skipping init template key check"
else
  init_out="$tmp/init.toml"
  mkdir -p "$tmp/init-dest"
  if ! template_prompts_covered "$template"; then
    echo "init-template fail"
    failed=1
  elif ! run_chezmoi \
    --source "$repo_root" \
    --destination "$tmp/init-dest" \
    --persistent-state "$tmp/init.state" \
    execute-template --init \
    "${prompt_args[@]}" \
    <"$template" >"$init_out"
  then
    echo "init-template fail"
    failed=1
  else
    init_keys="$(data_keys "$init_out")"
    init_ok=0
    for name in "${profile_names[@]}"; do
      profile_keys="$(data_keys "${repo_root}/tests/profiles/${name}.toml")"
      if [[ "$init_keys" != "$profile_keys" ]]; then
        echo "init template [data] keys differ from ${name}" >&2
        diff -u <(printf '%s\n' "$profile_keys") <(printf '%s\n' "$init_keys") >&2 || true
        init_ok=1
      fi
    done
    if [[ "$init_ok" -eq 0 ]]; then
      echo "init-template pass"
    else
      echo "init-template fail"
      failed=1
    fi
  fi
fi

repo_after="$tmp/repo-after"
home_after="$tmp/home-after"
snapshot_repo >"$repo_after"
snapshot_home_chezmoi >"$home_after"
isolation_ok=0
if ! diff -u "$repo_before" "$repo_after" >&2; then
  echo "repo changed outside .bin during tests" >&2
  isolation_ok=1
fi
if ! diff -u "$home_before" "$home_after" >&2; then
  echo "chezmoi wrote under the real home directory" >&2
  isolation_ok=1
fi
if [[ "$isolation_ok" -eq 0 ]]; then
  echo "isolation pass"
else
  echo "isolation fail"
  failed=1
fi

exit "$failed"
