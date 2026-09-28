#!/usr/bin/env bash
# Harness and CI only. Machines are set up with the chezmoi one-liner in PLAN.md.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

install_chezmoi() {
  mkdir -p .bin
  if [[ -x .bin/chezmoi ]]; then
    return 0
  fi
  if ! command -v curl >/dev/null 2>&1; then
    echo "curl is required to install chezmoi" >&2
    return 1
  fi
  # get.chezmoi.io is the official installer. "--" is sh's command name so
  # -b is passed through to the installer as its bin directory.
  sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ./.bin
}

install_missing_packages() {
  local missing=()
  local cmd
  for cmd in zsh shellcheck git; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing+=("$cmd")
    fi
  done
  if [[ ${#missing[@]} -eq 0 ]]; then
    return 0
  fi

  case "$(uname -s)" in
    Linux)
      if ! command -v apt-get >/dev/null 2>&1; then
        echo "apt-get is required to install: ${missing[*]}" >&2
        return 1
      fi
      sudo apt-get update
      sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${missing[@]}"
      ;;
    Darwin)
      if ! command -v brew >/dev/null 2>&1; then
        echo "brew is required to install: ${missing[*]}" >&2
        return 1
      fi
      brew install "${missing[@]}"
      ;;
    *)
      echo "unsupported OS $(uname -s); install: ${missing[*]}" >&2
      return 1
      ;;
  esac
}

install_chezmoi
install_missing_packages
.bin/chezmoi --version >/dev/null
