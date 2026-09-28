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

plan_data_keys() {
  awk '
    /^## Template data$/ { section = 1; next }
    section && /^## / { exit }
    section && index($0, "|") {
      n = split($0, cols, "|")
      if (n < 6) next
      raw = cols[2]
      if (index(raw, "`") == 0) next
      key = raw
      gsub(/[[:space:]]/, "", key)
      gsub(/`/, "", key)
      if (key ~ /^[A-Za-z_][A-Za-z0-9_]*$/) print key
    }
  ' "$repo_root/PLAN.md" | LC_ALL=C sort -u
}

# Prompt strings come from the Template data table. Answers are fixed here.
plan_prompts() {
  awk '
    /^## Template data$/ { section = 1; next }
    section && /^## / { exit }
    section && index($0, "|") {
      n = split($0, cols, "|")
      if (n < 6) next
      prompt = cols[5]
      gsub(/^[[:space:]]+/, "", prompt)
      gsub(/[[:space:]]+$/, "", prompt)
      if (substr(prompt, 1, 1) != "`") next
      len = length(prompt)
      if (substr(prompt, len, 1) != "`") next
      prompt = substr(prompt, 2, len - 2)
      type = cols[3]
      gsub(/[[:space:]]/, "", type)
      key = cols[2]
      gsub(/[[:space:]]/, "", key)
      gsub(/`/, "", key)
      printf "%s\t%s\t%s\n", type, key, prompt
    }
  ' "$repo_root/PLAN.md"
}

prompt_args=()
load_prompt_args() {
  local type key prompt answer
  prompt_args=()
  while IFS=$'\t' read -r type key prompt; do
    [[ -n "$key" ]] || continue
    case "$key" in
      headless) answer=true ;;
      work) answer=false ;;
      workEmail) answer="" ;;
      windowsUser) answer="" ;;
      *)
        echo "no hard-coded prompt answer for ${key}" >&2
        return 1
        ;;
    esac
    case "$type" in
      bool) prompt_args+=(--promptBool "${prompt}=${answer}") ;;
      string) prompt_args+=(--promptString "${prompt}=${answer}") ;;
      *)
        echo "unsupported prompt type ${type} for ${key}" >&2
        return 1
        ;;
    esac
  done < <(plan_prompts)
  if [[ ${#prompt_args[@]} -ne 8 ]]; then
    echo "expected 4 prompts in the Template data table" >&2
    return 1
  fi
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

  if [[ -e "$out/PLAN.md" || -e "$out/README.md" || -e "$out/scripts/test.sh" ]]; then
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

plan_keys="$(plan_data_keys)"
if [[ -z "$plan_keys" ]]; then
  echo "failed to parse Template data keys from PLAN.md" >&2
  exit 1
fi
load_prompt_args

repo_before="$tmp/repo-before"
home_before="$tmp/home-before"
snapshot_repo >"$repo_before"
snapshot_home_chezmoi >"$home_before"

failed=0
profile_names=(darwin linux-server linux-desktop wsl)
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
    if [[ "$got" != "$plan_keys" ]]; then
      echo "${name}: [data] keys do not match the Template data table" >&2
      diff -u <(printf '%s\n' "$plan_keys") <(printf '%s\n' "$got") >&2 || true
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

template="${repo_root}/home/.chezmoi.toml.tmpl"
if [[ ! -f "$template" ]]; then
  echo "notice: home/.chezmoi.toml.tmpl does not exist; skipping init template key check"
else
  init_out="$tmp/init.toml"
  mkdir -p "$tmp/init-dest"
  if ! run_chezmoi \
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
