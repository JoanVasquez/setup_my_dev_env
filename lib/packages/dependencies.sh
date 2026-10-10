#!/usr/bin/env bash
# Keep optional user selections separate from configuration requirements. A queue
# expands the manifest transitively; visited nodes prevent duplicates and cycles.
append_unique() {
    local array_name="$1" value="$2"
    # A Bash nameref edits the caller's array rather than a temporary copy.
    local -n values="$array_name"
    [[ " ${values[*]} " == *" $value "* ]] || values+=("$value")
    return 0
}
direct_dependencies() {
    local component="$1" key requirements
    while read -r key requirements; do
        [[ "$key" == "$component" ]] || continue
        printf '%s\n' "$requirements"
    done < "$ROOT/packages/dependencies.tsv"
    case "$component" in
        fish) [[ "$(os_field ID)" != cachyos ]] || printf 'fish-cachyos\n' ;;
        # A present Codex does not need another Node installation merely to be skipped.
        codex) codex_present || printf 'nvm\n' ;;
    esac
    return 0
}
resolve_dependencies() {
    resolved_components=()
    automatic_components=()
    local -a queue=("$@") visited=()
    local index=0 component requirement
    while ((index < ${#queue[@]})); do
        component="${queue[index]}"
        index=$((index + 1))
        [[ " ${visited[*]} " != *" $component "* ]] || continue
        visited+=("$component")
        # fish-cachyos is a grouping node, not a package or executable.
        [[ "$component" == fish-cachyos ]] || append_unique resolved_components "$component"
        for requirement in $(direct_dependencies "$component"); do
            queue+=("$requirement")
        done
    done
    for component in "${resolved_components[@]}"; do
        [[ " $* " == *" $component "* ]] || automatic_components+=("$component")
    done
}
# Used before/while asking tool questions. Requirements already implied by the
# shell or an optional selection are shown in the plan, not offered for rejection.
refresh_wizard_dependencies() {
    local -a roots=()
    [[ "$shell_choice" == none ]] || roots+=("$shell_choice")
    local -a selected_tools=()
    if [[ -n "$tools" && "$tools" != none ]]; then IFS=, read -r -a selected_tools <<< "$tools"; fi
    roots+=("${selected_tools[@]}")
    resolve_dependencies "${roots[@]}"
}
