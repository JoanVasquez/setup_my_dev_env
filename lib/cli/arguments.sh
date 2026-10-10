#!/usr/bin/env bash
# Set per-invocation options and validate flags before any system probing.
parse_arguments() {
    # No subcommand means the interactive wizard. Consume a command only if it is not a flag.
    cmd=setup
    if (($#)) && [[ "$1" != -* ]]; then cmd="$1"; shift; fi
    case "$cmd" in setup|install|unlink|packages|doctor|aliases) ;; *) usage >&2; exit 2 ;; esac
    # Flags are integer booleans: 0 means off, 1 means on; ((flag)) checks them.
    # selected is the comma-separated config list used by install/unlink.
    all=0 dry=0 yes=0 extra=0 selected=""
    # -1 defers the default-shell decision until command and config-only mode are resolved.
    no_packages=0 login_shell=-1 enable_docker=0 docker_group=0 system_zshenv=0
    # Explicit-choice flags tell the wizard which questions the CLI already answered.
    shell_choice=auto terminal_choice=auto shell_explicit=0 terminal_explicit=0 tools_explicit=0
    tools="$default_tools"
    # Parse arguments in order. The first case checks command-specific flag validity;
    # the second stores values. shift removes an argument from the remaining input.
    while (($#)); do
        case "$1" in
            --all|--components) [[ "$cmd" == install || "$cmd" == unlink ]] || die "$1 applies to install/unlink only" ;;
            --extra) [[ "$cmd" == packages ]] || die '--extra applies to packages only' ;;
            --shell) [[ "$cmd" == setup || "$cmd" == packages || "$cmd" == aliases ]] || die '--shell applies to setup/packages/aliases only' ;;
            --terminal|--tools|--enable-docker|--docker-group) [[ "$cmd" == setup || "$cmd" == packages ]] || die "$1 applies to setup/packages only" ;;
            --no-packages|--login-shell|--keep-shell|--system-zshenv) [[ "$cmd" == setup ]] || die "$1 applies to setup only" ;;
        esac
        case "$1" in
            --all) all=1 ;;
            --dry-run) dry=1 ;;
            --yes) yes=1 ;;
            --extra) extra=1 ;;
            --no-packages) no_packages=1 ;;
            --login-shell) login_shell=1 ;;
            --keep-shell) login_shell=0 ;;
            --system-zshenv) system_zshenv=1 ;;
            --enable-docker) enable_docker=1 ;;
            --docker-group) docker_group=1 ;;
            --components|--shell|--terminal|--tools)
                [[ $# -ge 2 && -n "$2" && "$2" != --* ]] || die "Missing value for $1"
                case "$1" in
                    --components) selected="$2" ;;
                    --shell) shell_choice="$2"; shell_explicit=1 ;;
                    --terminal) terminal_choice="$2"; terminal_explicit=1 ;;
                    --tools) tools="$2"; tools_explicit=1 ;;
                esac
                # A value-taking option consumes both the option and its following value.
                shift ;;
            -h|--help) usage; exit 0 ;;
            *) die "Unknown option: $1" ;;
        esac
        shift
    done
}
