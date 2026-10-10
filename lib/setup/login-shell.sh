#!/usr/bin/env bash
# Changing a shell startup file does not change the account's login shell.
# Setup activates its selected shell after installation/linking. Only shell paths
# registered by the system are accepted; --keep-shell disables this step.
change_login_shell() {
    ((login_shell)) || return 0
    if ((dry)); then printf 'Change login shell to %s using chsh\n' "$shell_choice"; return; fi
    local path current registry="${SHELLS_FILE:-/etc/shells}"
    path="$(command -v "$shell_choice")" || die "Shell missing: $shell_choice"
    [[ "$path" == /* ]] || die 'Expected an absolute shell executable path'
    [[ -r "$registry" ]] || die "Cannot read the registered shell list: $registry"
    if ! grep -Fxq "$path" "$registry"; then
        # Some systems list /bin while PATH resolves /usr/bin (or vice versa).
        local listed
        while read -r listed; do
            if [[ "$listed" == /* && "$listed" -ef "$path" ]]; then path="$listed"; break; fi
        done < "$registry"
    fi
    grep -Fxq "$path" "$registry" || die "$path is not registered in $registry"
    current="$(account_shell)"
    # /bin and /usr/bin may name the same executable. Compare files as well as strings.
    if [[ "$current" == "$path" || ( -n "$current" && "$current" -ef "$path" ) ]]; then
        printf 'skip: %s is already your default login shell\n' "$shell_choice"
        return
    fi
    # Use the invoking user explicitly; sudo must not accidentally change root's shell.
    privileged chsh -s "$path" "$(id -un)"
    printf 'Default login shell set to %s. Log out and back in to use it.\n' "$shell_choice"
}
