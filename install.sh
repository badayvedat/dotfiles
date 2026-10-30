#!/bin/bash
set -euo pipefail

component=${1:-}
if [[ $# -ne 1 || ( "$component" != all && "$component" != zsh && "$component" != rex ) ]]; then
  printf 'Usage: %s {all|zsh|rex}\n' "$0" >&2
  exit 2
fi

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
rex_config=${REX_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/rex/init.lua}
zshrc=${ZDOTDIR:-$HOME}/.zshrc
sources=()
targets=()
if [[ "$component" != zsh ]]; then
  sources+=("$repo_dir/rex/init.lua")
  targets+=("$rex_config")
fi
if [[ "$component" != rex ]]; then
  sources+=("$repo_dir/zsh/selection.zsh")
  targets+=("$HOME/.zsh/selection.zsh")
fi
source_block='if [[ -n "$REX_SESSION" ]]; then
  source "$HOME/.zsh/selection.zsh"
fi'

# Check every destination before making any changes.
for i in "${!targets[@]}"; do
  target=${targets[$i]}
  if [[ -L "$target" ]] && [[ $(readlink "$target") == "${sources[$i]}" ]]; then
    continue
  fi
  if [[ -e "$target" || -L "$target" ]]; then
    printf 'Refusing to overwrite %s. Move it aside and rerun.\n' "$target" >&2
    exit 1
  fi
done
if [[ "$component" != rex && ( -e "$zshrc" || -L "$zshrc" ) && ! -f "$zshrc" ]]; then
  printf 'Not a regular file: %s\n' "$zshrc" >&2
  exit 1
fi

if [[ "$component" != zsh ]] && command -v rex >/dev/null 2>&1; then
  rex config check "$repo_dir/rex/init.lua"
fi

for i in "${!targets[@]}"; do
  target=${targets[$i]}
  if [[ ! -L "$target" ]]; then
    mkdir -p -- "$(dirname -- "$target")"
    ln -s -- "${sources[$i]}" "$target"
  fi
done

if [[ "$component" != rex ]]; then
  zshrc_contents=''
  if [[ -f "$zshrc" ]]; then
    zshrc_contents=$(<"$zshrc")
  fi
  if [[ "$zshrc_contents" != *"$source_block"* ]]; then
    mkdir -p -- "$(dirname -- "$zshrc")"
    printf '\n%s\n' "$source_block" >> "$zshrc"
  fi
fi

if [[ "$component" != zsh ]] && command -v rex >/dev/null 2>&1; then
  if ! rex --autostart=false config reload; then
    printf 'Config installed, but Rex could not reload. Run rex config reload when the local server is available.\n' >&2
  fi
fi

printf 'Installed %s configuration from %s\n' "$component" "$repo_dir"
if [[ "$component" != rex ]]; then
  printf 'Open a new Rex shell, or run: source "$HOME/.zsh/selection.zsh"\n'
fi
