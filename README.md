# dotfiles

Configure Rex shortcuts and zsh text selection.

## Requirements

- Bash
- zsh
- Rex
- macOS for system clipboard shortcuts

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
| Cmd+C | Copy mouse-selected terminal text. |
| Esc, then lowercase w | Copy the zsh selection to the system clipboard. |
| Cmd+X | Cut the zsh selection to the system clipboard. |
| Shift+Left/Right | Select characters. |
| Shift+Option+Left/Right | Select words. |
| Shift+Cmd+Left/Right | Select text to the start or end of the line. |

Type or paste to replace selected text.
Press Backspace or Delete to delete selected text.
Move without Shift to clear the selection.
Option and Cmd movement keep their normal behavior.
Ctrl+C still interrupts commands.

## Scope

Selection works at the zsh prompt in Rex.
It supports Emacs mode and vi insert mode.
Cmd+C uses Rex’s normal terminal copy behavior.
Cmd+X acts on shell selections, not terminal output.
Other terminal applications can respond differently to Cmd+X.
