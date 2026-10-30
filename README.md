# dotfiles

Configure Rex shortcuts and zsh text selection.

## Requirements

- Bash
- zsh
- Rex

## Install

Clone this repository.
Run one command from the repository directory:

| Command | Action |
| --- | --- |
| `./install.sh all` | Install both configurations. |
| `./install.sh rex` | Install only Rex shortcuts. |
| `./install.sh zsh` | Install only zsh selection support. |

Keep the repository in the same location after installation.
Open a new Rex shell to activate selection.

You can run the installer again.
It does not overwrite unrelated files.
If it reports a conflict, move the conflicting file before you retry.

## Shortcuts

| Keys | Action |
| --- | --- |
| Ctrl+Cmd+Left/Right | Go to the previous or next Rex tab. |
| Shift+Left/Right | Select characters. |
| Shift+Option+Left/Right | Select words. |
| Shift+Cmd+Left/Right | Select text to the start or end of the line. |

Type or paste to replace selected text.
Press Backspace or Delete to delete selected text.
Move without Shift to clear the selection.
Option and Cmd movement keep their normal behavior.

## Scope

Selection works at the zsh prompt in Rex.
It supports Emacs mode and vi insert mode.
It does not select terminal output or change editing inside other applications.
