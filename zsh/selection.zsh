(( $+functions[_dotfiles_select] )) && return

_dotfiles_selection_is_current() {
    # Autosuggestions can change LASTWIDGET without moving the cursor.
    (( ${_dotfiles_selection_active:-0} && REGION_ACTIVE && CURSOR == ${_dotfiles_selection_cursor:--1} )) &&
        [[ "$LASTWIDGET" == dotfiles-select-* || "$LASTWIDGET" == dotfiles-clipboard-* || "$LASTWIDGET" == autosuggest-* ]]
}

_dotfiles_select() {
    _dotfiles_selection_is_current || MARK=$CURSOR
    zle ".${WIDGET#dotfiles-select-}"
    REGION_ACTIVE=1
    typeset -g _dotfiles_selection_active=1 _dotfiles_selection_cursor=$CURSOR
}

_dotfiles_edit_selection() {
    local widget=$1
    shift
    if _dotfiles_selection_is_current && (( CURSOR != MARK )); then
        # Preserve the yank buffer while replacing selected text.
        () {
            local CUTBUFFER
            local -a killring
            zle .kill-region
        }
        REGION_ACTIVE=0
        _dotfiles_selection_active=0
        POSTDISPLAY=''
        case "$widget" in
            *delete*|*kill*) return 0 ;;
        esac
    fi
    zle "_dotfiles_original_$widget" -- "$@"
}

_dotfiles_clipboard_selection() {
    _dotfiles_selection_is_current && (( CURSOR != MARK )) || return 0

    local text
    () {
        local CUTBUFFER
        local -a killring
        zle .copy-region-as-kill
        text=$CUTBUFFER
    }
    if ! printf '%s' "$text" | pbcopy; then
        zle -M 'Cannot copy selection to the macOS clipboard.'
        return 1
    fi

    if [[ "$WIDGET" == dotfiles-clipboard-cut ]]; then
        zle .kill-region
        REGION_ACTIVE=0
        _dotfiles_selection_active=0
        POSTDISPLAY=''
    else
        zle .copy-region-as-kill
    fi
}
zle -N dotfiles-clipboard-copy _dotfiles_clipboard_selection
zle -N dotfiles-clipboard-cut _dotfiles_clipboard_selection

_dotfiles_selection_redraw() {
    if (( ${_dotfiles_selection_active:-0} )) && ! _dotfiles_selection_is_current; then
        REGION_ACTIVE=0
        _dotfiles_selection_active=0
    fi
    return 0
}
builtin autoload -Uz add-zle-hook-widget
add-zle-hook-widget line-pre-redraw _dotfiles_selection_redraw

() {
    local map motion hook widget
    local -a hooks ordered=(0:_dotfiles_selection_redraw)
    # Clear stale selections before syntax-highlighting redraw hooks run.
    zstyle -a zle-line-pre-redraw widgets hooks
    for hook in "${hooks[@]}"; do
        [[ "${hook#*:}" == _dotfiles_selection_redraw ]] && continue
        ordered+=("$(( ${hook%%:*} + 1 )):${hook#*:}")
    done
    zstyle zle-line-pre-redraw widgets "${ordered[@]}"

    for widget in self-insert self-insert-unmeta quoted-insert vi-quoted-insert magic-space bracketed-paste yank \
        backward-delete-char vi-backward-delete-char delete-char delete-char-or-list vi-delete-char \
        backward-delete-word backward-kill-word vi-backward-kill-word kill-word backward-kill-line kill-line kill-whole-line; do
        zle -A "$widget" "_dotfiles_original_$widget"
        eval "_dotfiles_edit_${widget}() { _dotfiles_edit_selection ${(q)widget} \"\$@\"; }"
        zle -N "$widget" "_dotfiles_edit_$widget"
    done

    for motion in backward-char forward-char backward-word forward-word beginning-of-line end-of-line; do
        zle -N "dotfiles-select-$motion" _dotfiles_select
    done
    for map in emacs viins; do
        bindkey -M "$map" '^[w' dotfiles-clipboard-copy
        bindkey -M "$map" '^[^W' dotfiles-clipboard-cut
        bindkey -M "$map" '^[[1;2D' dotfiles-select-backward-char
        bindkey -M "$map" '^[[1;2C' dotfiles-select-forward-char
        bindkey -M "$map" '^[[1;4D' dotfiles-select-backward-word
        bindkey -M "$map" '^[[1;4C' dotfiles-select-forward-word
        bindkey -M "$map" '^[[1;10D' dotfiles-select-beginning-of-line
        bindkey -M "$map" '^[[1;10C' dotfiles-select-end-of-line
    done
}
