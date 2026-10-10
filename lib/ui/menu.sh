#!/usr/bin/env bash
# Dependency-free menus. Values and display labels stay separate; output goes to
# stderr and results are assigned in the caller's scope, never captured from UI.
# Only the short focus line is redrawn, avoiding wrapped-row cursor accounting.
menu_key() {
    local input_key sequence
    IFS= read -r -s -n 1 input_key || die 'Input closed'
    case "$input_key" in
        $'\033')
            IFS= read -r -s -n 1 -t 0.2 sequence || true
            if [[ "$sequence" == '[' || "$sequence" == O ]]; then
                IFS= read -r -s -n 1 -t 0.2 sequence || true
                case "$sequence" in A) input_key=k ;; B) input_key=j ;; *) input_key=ignored ;; esac
            else input_key=ignored; fi ;;
        q|Q) die 'Selection cancelled' ;;
    esac
    printf -v "$1" '%s' "$input_key"
}
# Arguments: output variable, title, default CSV, single|multiple, then values.
# Optional menu_labels array provides descriptive labels in the same order.
prompt_menu() {
    local output_variable="$1" title="$2" defaults="$3" mode="$4"
    shift 4
    local -a options=("$@") checked=() selected_values=()
    local focus=0 row key ansi=0 mark count csv
    ((${#options[@]})) || { printf -v "$output_variable" '%s' none; return; }
    [[ -t 2 && "${TERM:-dumb}" != dumb ]] && ansi=1
    printf '\n%s\n' "$title" >&2
    for row in "${!options[@]}"; do
        checked[row]=0
        if contains "$defaults" "${options[row]}"; then
            checked[row]=1
            [[ "$mode" != single ]] || focus="$row"
        fi
        mark=''; [[ "$mode" != multiple ]] || mark='[ ] '
        printf '   %d) %s%s\n' "$((row + 1))" "$mark" "${menu_labels[row]:-${options[row]}}" >&2
    done
    if [[ "$mode" == multiple ]]; then
        printf 'Up/Down or j/k: move | Space: toggle | a: all | n: none | Enter: done | q: cancel\n' >&2
    else
        printf 'Up/Down or j/k: move | Enter: select | number: highlight | q: cancel\n' >&2
    fi
    while true; do
        (( !ansi )) || printf '\r\033[2K' >&2
        if [[ "$mode" == multiple ]]; then
            count=0; selected_values=()
            for row in "${!options[@]}"; do
                if ((checked[row])); then count=$((count + 1)); selected_values+=("${options[row]}"); fi
            done
            mark=' '; (( !checked[focus] )) || mark=x
            printf '[%s] %s | %d selected' "$mark" "${options[focus]}" "$count" >&2
        else printf 'Selection: %s' "${options[focus]}" >&2; fi
        ((ansi)) || printf '\n' >&2
        menu_key key
        case "$key" in
            '')
                (( !ansi )) || printf '\n' >&2
                if [[ "$mode" == single ]]; then csv="${options[focus]}"
                else
                    csv="$(IFS=,; printf '%s' "${selected_values[*]}")"
                    printf 'Selected tools: %s\n' "${csv:-none}" >&2
                fi
                printf -v "$output_variable" '%s' "${csv:-none}"
                return ;;
            k) focus=$(((focus + ${#options[@]} - 1) % ${#options[@]})) ;;
            j) focus=$(((focus + 1) % ${#options[@]})) ;;
            [1-9]) if ((key <= ${#options[@]})); then focus=$((key - 1)); fi ;;
            ' ') [[ "$mode" != multiple ]] || checked[focus]=$((1 - checked[focus])) ;;
            a|n|N)
                if [[ "$mode" == multiple ]]; then
                    for row in "${!options[@]}"; do
                        checked[row]=0; [[ "$key" != a ]] || checked[row]=1
                    done
                elif [[ "${options[*]}" == 'no yes' ]]; then focus=0; fi ;;
            y|Y) [[ "${options[*]}" != 'no yes' ]] || focus=1 ;;
        esac
    done
}
prompt_choice() {
    local -a menu_labels=()
    prompt_menu "$1" "$2" "$3" single "${@:4}"
}
prompt_boolean() {
    local variable="$1" label="$2" menu_answer
    prompt_choice menu_answer "$label" no no yes
    case "$menu_answer" in
        yes) printf -v "$variable" 1 ;;
        no) printf -v "$variable" 0 ;;
    esac
}

# Preview mode cannot change anything; --yes is an explicit unattended acceptance.
# Otherwise require a terminal and an affirmative answer before applying changes.
confirm() {
    ((dry || yes)) && return 0
    [[ -t 0 ]] || die "Use --yes for unattended changes, or --dry-run to preview."
    local proceed=0
    prompt_boolean proceed 'Proceed?'
    ((proceed))
}
