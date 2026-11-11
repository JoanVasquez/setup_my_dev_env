#!/usr/bin/env bash
# Dependency-free keyboard menus. Interactive terminals get a compact live view;
# redirected/dumb terminals retain line-oriented output for logs and tests.
declare -F ui_init >/dev/null || source "${BASH_SOURCE[0]%/*}/style.sh"

menu_key() {
    local input_key sequence
    IFS= read -r -s -n 1 input_key || die 'Input closed'
    case "$input_key" in
        $'\033')
            IFS= read -r -s -n 1 -t 0.2 sequence || true
            if [[ "$sequence" == '[' || "$sequence" == O ]]; then
                IFS= read -r -s -n 1 -t 0.2 sequence || true
                case "$sequence" in
                    A) input_key=k ;;
                    B) input_key=j ;;
                    H) input_key=home ;;
                    F) input_key=end ;;
                    *) input_key=ignored ;;
                esac
            else input_key=ignored; fi ;;
        q|Q) die 'Selection cancelled' ;;
    esac
    printf -v "$1" '%s' "$input_key"
}

menu_selected_values() {
    local row
    selected_values=()
    count=0
    for row in "${!options[@]}"; do
        if ((checked[row])); then
            count=$((count + 1))
            selected_values+=("${options[row]}")
        fi
    done
}

menu_render_live() {
    local row label marker pointer number current max_label
    max_label=$((${COLUMNS:-80} - 15))
    ((max_label >= 20)) || max_label=20
    printf '\033[2K%s╭─ %s%s%s\n' "$UI_ACCENT" "$UI_BOLD" "$title" "$UI_RESET" >&2
    for row in "${!options[@]}"; do
        label="${menu_labels[row]:-${options[row]}}"
        if ((${#label} > max_label)); then label="${label:0:max_label-1}…"; fi
        pointer=' '
        [[ "$row" != "$focus" ]] || pointer='›'
        if [[ "$mode" == multiple ]]; then
            marker='[ ]'
            (( !checked[row] )) || marker="${UI_SUCCESS}[✓]${UI_RESET}"
        else
            marker='○'
            [[ "$row" != "$focus" ]] || marker="${UI_ACCENT}●${UI_RESET}"
        fi
        number="$((row + 1))."
        if [[ "$row" == "$focus" ]]; then
            printf '\033[2K%s│ %s %s %2s  %s%s%s\n' "$UI_ACCENT" "$pointer" "$marker" "$number" "$UI_BOLD" "$label" "$UI_RESET" >&2
        else
            printf '\033[2K%s│%s   %s %2s  %s\n' "$UI_MUTED" "$UI_RESET" "$marker" "$number" "$label" >&2
        fi
    done
    printf '\033[2K%s╰%s\n' "$UI_ACCENT" "$UI_RESET" >&2
    if [[ "$mode" == multiple ]]; then
        printf '\033[2K%s  ↑/↓ move · Space toggle · Enter confirm%s\n' "$UI_MUTED" "$UI_RESET" >&2
        printf '\033[2K%s  A all · N none · Home/End jump · Q cancel%s\n' "$UI_MUTED" "$UI_RESET" >&2
        menu_selected_values
        current='[ ]'; (( !checked[focus] )) || current='[✓]'
        printf '\033[2K%s  %s %s · %d selected%s\n' "$UI_ACCENT" "$current" "${options[focus]}" "$count" "$UI_RESET" >&2
    else
        printf '\033[2K%s  ↑/↓ move · Enter confirm%s\n' "$UI_MUTED" "$UI_RESET" >&2
        printf '\033[2K%s  Home/End jump · Q cancel%s\n' "$UI_MUTED" "$UI_RESET" >&2
        printf '\033[2K%s  Selected: %s%s\n' "$UI_ACCENT" "${options[focus]}" "$UI_RESET" >&2
    fi
}

menu_render_plain() {
    local row mark
    printf '\n%s\n' "$title" >&2
    for row in "${!options[@]}"; do
        mark=''; [[ "$mode" != multiple ]] || mark='[ ] '
        printf '   %d) %s%s\n' "$((row + 1))" "$mark" "${menu_labels[row]:-${options[row]}}" >&2
    done
    if [[ "$mode" == multiple ]]; then
        printf 'Up/Down or j/k: move | Space: toggle | a: all | n: none | Enter: done | q: cancel\n' >&2
    else
        printf 'Up/Down or j/k: move | Enter: select | number: highlight | q: cancel\n' >&2
    fi
}

# Arguments: output variable, title, default CSV, single|multiple, then values.
# Optional menu_labels array provides descriptive labels in the same order.
prompt_menu() {
    local output_variable="$1" title="$2" defaults="$3" mode="$4"
    shift 4
    local -a options=("$@") checked=() selected_values=()
    local focus=0 row key ansi=0 mark count=0 csv height first=1
    ((${#options[@]})) || { printf -v "$output_variable" '%s' none; return; }
    [[ -t 2 && "${TERM:-dumb}" != dumb ]] && ansi=1
    ui_init 2
    for row in "${!options[@]}"; do
        checked[row]=0
        if contains "$defaults" "${options[row]}"; then
            checked[row]=1
            [[ "$mode" != single ]] || focus="$row"
        fi
    done
    if ((ansi)); then
        printf '\n' >&2
        height=$((${#options[@]} + 5))
    else
        menu_render_plain
    fi
    while true; do
        if ((ansi)); then
            ((first)) || printf '\033[%dA' "$height" >&2
            menu_render_live
            first=0
        else
            if [[ "$mode" == multiple ]]; then
                menu_selected_values
                mark=' '; (( !checked[focus] )) || mark=x
                printf '[%s] %s | %d selected\n' "$mark" "${options[focus]}" "$count" >&2
            else printf 'Selection: %s\n' "${options[focus]}" >&2; fi
        fi
        menu_key key
        case "$key" in
            '')
                if [[ "$mode" == single ]]; then csv="${options[focus]}"
                else
                    menu_selected_values
                    csv="$(IFS=,; printf '%s' "${selected_values[*]}")"
                    ((ansi)) || printf 'Selected tools: %s\n' "${csv:-none}" >&2
                fi
                printf -v "$output_variable" '%s' "${csv:-none}"
                return ;;
            k) focus=$(((focus + ${#options[@]} - 1) % ${#options[@]})) ;;
            j) focus=$(((focus + 1) % ${#options[@]})) ;;
            home) focus=0 ;;
            end) focus=$((${#options[@]} - 1)) ;;
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
confirm() {
    ((dry || yes)) && return 0
    [[ -t 0 ]] || die "Use --yes for unattended changes, or --dry-run to preview."
    local proceed=0
    prompt_boolean proceed 'Apply this plan?'
    ((proceed))
}
