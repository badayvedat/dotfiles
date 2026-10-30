#!/bin/bash
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
tmp=$(mktemp -d)
trap '/bin/rm -rf -- "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/home"
for command in dirname mkdir ln readlink; do
  ln -s "$(command -v "$command")" "$tmp/bin/$command"
done

export HOME="$tmp/home" PATH="$tmp/bin"
unset REX_CONFIG XDG_CONFIG_HOME ZDOTDIR

/bin/bash "$repo_dir/install.sh" all
[[ $(readlink "$HOME/.config/rex/init.lua") == "$repo_dir/rex/init.lua" ]]
[[ $(readlink "$HOME/.zsh/selection.zsh") == "$repo_dir/zsh/selection.zsh" ]]
/usr/bin/grep -Fq 'source "$HOME/.zsh/selection.zsh"' "$HOME/.zshrc"
/bin/cp "$HOME/.zshrc" "$tmp/first.zshrc"
/bin/bash "$repo_dir/install.sh" all
/usr/bin/cmp "$tmp/first.zshrc" "$HOME/.zshrc"

for component in zsh rex; do
  export HOME="$tmp/only-$component"
  /bin/mkdir -p "$HOME"
  if [[ "$component" == zsh ]]; then
    /bin/mkdir -p "$HOME/.config/rex"
    printf 'keep rex\n' > "$HOME/.config/rex/init.lua"
  else
    /bin/mkdir -p "$HOME/.zsh"
    printf 'keep selection\n' > "$HOME/.zsh/selection.zsh"
    /bin/mkdir "$HOME/.zshrc"
  fi
  /bin/bash "$repo_dir/install.sh" "$component"
  if [[ "$component" == zsh ]]; then
    [[ -L "$HOME/.zsh/selection.zsh" && -f "$HOME/.zshrc" ]]
    [[ $(<"$HOME/.config/rex/init.lua") == 'keep rex' ]]
  else
    [[ -L "$HOME/.config/rex/init.lua" && -d "$HOME/.zshrc" ]]
    [[ $(<"$HOME/.zsh/selection.zsh") == 'keep selection' ]]
  fi
done

export HOME="$tmp/invalid"
/bin/mkdir -p "$HOME"
for args in '' unknown 'all extra'; do
  set -- $args
  status=0
  /bin/bash "$repo_dir/install.sh" "$@" || status=$?
  [[ $status == 2 && ! -e "$HOME/.zshrc" && ! -e "$HOME/.config" && ! -e "$HOME/.zsh" ]]
done

# Neither destination may be changed if the other conflicts.
for conflict in rex selection dangling; do
  export HOME="$tmp/$conflict"
  /bin/mkdir -p "$HOME/.zsh" "$HOME/.config/rex"
  case "$conflict" in
    rex) printf 'keep rex\n' > "$HOME/.config/rex/init.lua" ;;
    selection) printf 'keep selection\n' > "$HOME/.zsh/selection.zsh" ;;
    dangling) /bin/ln -s "$HOME/missing" "$HOME/.zsh/selection.zsh" ;;
  esac
  if /bin/bash "$repo_dir/install.sh" all; then
    printf 'Installer accepted conflicting %s destination\n' "$conflict" >&2
    exit 1
  fi
  [[ ! -e "$HOME/.zshrc" ]]
  if [[ "$conflict" == rex ]]; then
    [[ $(<"$HOME/.config/rex/init.lua") == 'keep rex' ]]
    [[ ! -L "$HOME/.zsh/selection.zsh" ]]
  else
    [[ ! -L "$HOME/.config/rex/init.lua" ]]
    if [[ "$conflict" == selection ]]; then
      [[ $(<"$HOME/.zsh/selection.zsh") == 'keep selection' ]]
    else
      [[ $(readlink "$HOME/.zsh/selection.zsh") == "$HOME/missing" ]]
    fi
  fi
done

export HOME="$tmp/custom home" XDG_CONFIG_HOME="$tmp/xdg config" ZDOTDIR="$tmp/zsh config"
/bin/mkdir -p "$ZDOTDIR"
printf 'export KEEP_ME=yes' > "$ZDOTDIR/.zshrc"
/bin/bash "$repo_dir/install.sh" all
[[ $(readlink "$XDG_CONFIG_HOME/rex/init.lua") == "$repo_dir/rex/init.lua" ]]
/usr/bin/grep -Fxq 'export KEEP_ME=yes' "$ZDOTDIR/.zshrc"
[[ ! -e "$HOME/.zshrc" ]]

export REX_CONFIG="$tmp/explicit config/init.lua"
/bin/bash "$repo_dir/install.sh" all
[[ $(readlink "$REX_CONFIG") == "$repo_dir/rex/init.lua" ]]

# Verify CLI validation and reload without contacting a real server.
printf '#!/bin/bash\nprintf "%%s\\n" "$*" >> "$HOME/rex.calls"\nif [[ $1 == config ]]; then exit "${CHECK_EXIT:-0}"; fi\nexit 1\n' > "$tmp/bin/rex"
/bin/chmod +x "$tmp/bin/rex"
export HOME="$tmp/cli" REX_CONFIG="$tmp/cli/rex.lua" ZDOTDIR="$tmp/cli"
/bin/mkdir -p "$HOME"
export CHECK_EXIT=1
if /bin/bash "$repo_dir/install.sh" all; then
  printf 'Installer ignored failed config validation\n' >&2
  exit 1
fi
[[ ! -L "$REX_CONFIG" && ! -L "$HOME/.zsh/selection.zsh" && ! -e "$HOME/.zshrc" ]]
export CHECK_EXIT=0
/bin/bash "$repo_dir/install.sh" all
/usr/bin/grep -Fxq "config check $repo_dir/rex/init.lua" "$HOME/rex.calls"
/usr/bin/grep -Fxq -- '--autostart=false config reload' "$HOME/rex.calls"
[[ -L "$REX_CONFIG" ]]
export HOME="$tmp/zsh-no-cli" ZDOTDIR="$tmp/zsh-no-cli"
/bin/mkdir -p "$HOME"
/bin/bash "$repo_dir/install.sh" zsh
[[ ! -e "$HOME/rex.calls" && ! -e "$HOME/.config" ]]
printf 'Installer tests passed.\n'
