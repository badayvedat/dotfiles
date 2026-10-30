# dotfiles

Personal Rex configuration and zsh command-line selection support.

## Setup

Clone this repository to `~/projects/dotfiles`. Move any existing destination files aside before creating these links:

```sh
mkdir -p ~/.config/rex ~/.zsh
ln -s ~/projects/dotfiles/rex/init.lua ~/.config/rex/init.lua
ln -s ~/projects/dotfiles/zsh/selection.zsh ~/.zsh/selection.zsh
```

Add this at the end of `~/.zshrc`, after autosuggestions and syntax highlighting:

```zsh
if [[ -n "$REX_SESSION" ]]; then
  source "$HOME/.zsh/selection.zsh"
fi
```

Then run `rex config check`, `rex config reload`, and open a new Rex shell. For an existing prompt, run `source ~/.zsh/selection.zsh`.

The Rex-only condition avoids installing selection twice in Brume, which supplies its own integration. To use this in another terminal, enable sourcing there only if it does not already install equivalent selection widgets.

## Shortcuts

- Ctrl+Cmd+Left/Right: previous/next Rex tab.
- Shift+Cmd+Left/Right: removed from Rex's default tab shortcuts and forwarded to the terminal.
- Shift+Left/Right: select characters at the shell prompt.
- Shift+Option+Left/Right: select words.
- Shift+Cmd+Left/Right: select to the beginning/end of the logical line.
- Typing, paste, Backspace, and Delete replace/delete the selected text.
- Unshifted movement clears the selection and preserves normal zsh motion behavior.

Selection supports zsh's Emacs and vi insert modes. It affects the editable command buffer, not terminal output or programs running inside the terminal. The terminal must emit CSI `1;2D/C`, `1;4D/C`, and `1;10D/C` for the corresponding Shift shortcuts; app-local shortcut overrides must not intercept them. If another terminal needs different sequences, add its bindings when adopting it.

## Tests

On macOS, with Expect and the Homebrew `zsh-autosuggestions` and `zsh-syntax-highlighting` plugins installed:

```sh
expect tests/selection.exp
```

These drive interactive zsh through a pseudo-terminal and check selection, replacement, paste, deletion, undo, cancellation, Unicode, multiline input, repeated sourcing, and both plugin-loading orders.

The selection implementation and tests are adapted from Brume's `Patches/libghostty-spm-zsh-selection.patch`, `Tests/ShellSelection/setup.zsh`, and `scripts/test-shell-selection.exp`. See `LICENSE.brume` for their MIT license.
