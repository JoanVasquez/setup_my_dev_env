#!/usr/bin/env bash
# Common helpers used by the CLI and every installer module.
# die prints to stderr and stops the whole installer with a nonzero exit status.
die() { printf 'Error: %s\n' "$*" >&2; exit 1; }
# Print a command with shell-escaped arguments (%q), then execute the original argv.
# A dry run prints only; it never evaluates the printed string as shell code.
run() {
    printf '+'
    printf ' %q' "$@"
    printf '\n'
    if ((dry)); then return 0; fi
    "$@"
}
# Keep sudo at the boundary of system changes; config links and downloads use your user.
privileged() { run sudo "$@"; }
# Test an exact item in a comma-separated list by adding delimiters on both sides.
contains() { [[ ",$1," == *",$2,"* ]]; }
# Arguments: selected CSV, then allowed item names. Abort on malformed/unknown items.
validate_list() {
    local list="$1" item
    shift
    [[ "$list" != ,* && "$list" != *, && "$list" != *,,* ]] || die "Invalid list: $list"
    local -a entries
    # IFS chooses commas as separators; -a stores tokens in a Bash array; -r keeps backslashes.
    IFS=, read -r -a entries <<< "$list"
    for item in "${entries[@]}"; do
        [[ " $* " == *" $item "* ]] || die "Unknown selection: $item (choose from: $*)"
    done
}
# Arguments: HTTPS URL, destination file. Save locally so download errors happen
# before execution. --fail rejects HTTP errors; redirects must also use HTTPS.
fetch_script() {
    local url="$1" output="$2"
    curl --fail --show-error --silent --location --proto '=https' --proto-redir '=https' \
        --tlsv1.2 --retry 3 --connect-timeout 15 --max-time 300 "$url" -o "$output"
}

# Preserve incomplete user installs before retrying. Download into a staging
# directory first so interrupted clones do not leave a falsely complete target.
install_plugin() {
    local repository="$1" destination="$2" entry="$3" staging archive
    if ((dry)); then
        printf 'Repair/install plugin: %s -> %s\n' "$repository" "$destination"
        run git clone --depth 1 "https://github.com/$repository.git" "$destination"
        return
    fi
    mkdir -p -- "$(dirname "$destination")"
    staging="$(mktemp -d "$work_dir/plugin.XXXXXX")"
    run git clone --depth 1 "https://github.com/$repository.git" "$staging/checkout"
    [[ -s "$staging/checkout/$entry" ]] || die "Missing plugin entrypoint: $repository/$entry"
    if [[ -e "$destination" || -L "$destination" ]]; then
        archive="$backup_dir/plugins/${repository##*/}"
        mkdir -p -- "$(dirname "$archive")"
        mv -- "$destination" "$archive"
        printf 'backup: %s\n' "$archive"
    fi
    mv -- "$staging/checkout" "$destination"
}

validate_choice() {
    local choice="$1"
    shift
    [[ "$choice" != *,* ]] || die "Choose one value: $choice"
    validate_list "$choice" "$@"
}
