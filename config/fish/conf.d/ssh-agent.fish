# Shared SSH agent for local sessions; preserve forwarded remote agents.
if test -z "$SSH_CONNECTION"; and test -z "$SSH_TTY"; and test -n "$XDG_RUNTIME_DIR"
    set -gx SSH_AUTH_SOCK "$XDG_RUNTIME_DIR/ssh-agent.socket"
end
