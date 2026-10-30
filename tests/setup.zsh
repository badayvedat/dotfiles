PS1='DOTFILES_TEST> '
RPS1=''

pbcopy() {
    (( _dotfiles_test_clipboard_failure )) && return 1
    IFS='' read -r -d '' _dotfiles_test_clipboard
    return 0
}

_dotfiles_test_plugins() {
    source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    _zsh_autosuggest_start
    source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
}
_dotfiles_test_self_insert() {
    if [[ $KEYS == '~' ]]; then
        LBUFFER+='CUSTOM'
    elif [[ $KEYS == '#' ]]; then
        zle magic-space
    else
        zle .self-insert
    fi
}
zle -N self-insert _dotfiles_test_self_insert
[[ $DOTFILES_TEST_PRELOADED == 1 ]] && _dotfiles_test_plugins
source zsh/selection.zsh
source zsh/selection.zsh

_dotfiles_test_seed() {
    BUFFER='jj edit something'
    CURSOR=12
    REGION_ACTIVE=0
    CUTBUFFER='PASTED'
    killring=('OLDER')
    _dotfiles_test_clipboard='CLIPBOARD_BEFORE'
    _dotfiles_test_clipboard_failure=0
}
_dotfiles_test_state() {
    local start=$(( CURSOR < MARK ? CURSOR : MARK ))
    local end=$(( CURSOR > MARK ? CURSOR : MARK ))
    local selected=''
    (( end > start && REGION_ACTIVE )) && selected=${BUFFER[start+1,end]}
    (( ! REGION_ACTIVE && ${region_highlight[(I)*standout*]} )) && selected=STALE_HIGHLIGHT
    print -r -- "STATE|$CURSOR|$MARK|$REGION_ACTIVE|$selected|"
}
_dotfiles_test_buffer() { print -r -- "EDIT|$CURSOR|$REGION_ACTIVE|${(V)BUFFER}|"; }
_dotfiles_test_clipboard_state() {
    print -r -- "CLIP|$CURSOR|$REGION_ACTIVE|${(V)BUFFER}|${(V)_dotfiles_test_clipboard}|${(V)CUTBUFFER}|"
}
_dotfiles_test_clipboard_fail() { _dotfiles_test_clipboard_failure=1; }
_dotfiles_test_clear() { BUFFER=''; CURSOR=0; REGION_ACTIVE=0; }
zle -N _dotfiles_test_clear
zle -N _dotfiles_test_seed
zle -N _dotfiles_test_state
zle -N _dotfiles_test_buffer
zle -N _dotfiles_test_clipboard_state
zle -N _dotfiles_test_clipboard_fail
for map in emacs viins; do
    bindkey -M $map '^Xs' _dotfiles_test_seed
    bindkey -M $map '^Xt' _dotfiles_test_state
    bindkey -M $map '^Xc' _dotfiles_test_clear
    bindkey -M $map '^Xb' _dotfiles_test_buffer
    bindkey -M $map '^Xu' undo
    bindkey -M $map '^[[3~' delete-char
    bindkey -M $map '^Xa' autosuggest-suggest
    bindkey -M $map '^Xg' magic-space
    bindkey -M $map '^Xy' yank
    bindkey -M $map '^Xp' _dotfiles_test_clipboard_state
    bindkey -M $map '^Xf' _dotfiles_test_clipboard_fail
done
[[ $DOTFILES_TEST_PRELOADED == 0 ]] && _dotfiles_test_plugins

_dotfiles_test_redraw() { print -r -- DRAW_READY; }
add-zle-hook-widget line-pre-redraw _dotfiles_test_redraw
print READY
