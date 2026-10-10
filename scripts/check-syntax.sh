#!/usr/bin/env bash
# Run the project's offline checks without modifying your shell configuration.
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
for executable in bash fish zsh python3; do
    command -v "$executable" >/dev/null || { printf 'Missing check dependency: %s\n' "$executable" >&2; exit 1; }
done
while IFS= read -r -d '' file; do bash -n "$file"; done < <(
    find "$ROOT/lib" "$ROOT/scripts" "$ROOT/shell/common" "$ROOT/shell/bash" "$ROOT/config/tmux" -type f -name '*.sh' -print0
)
for file in "$ROOT/bin/dotfiles" "$ROOT/bin/check" "$ROOT/shell/common/node-bin" "$ROOT/shell/bash/bashrc"; do bash -n "$file"; done
for file in "$ROOT/config/zsh/.zshenv" "$ROOT/config/zsh/.zshrc" "$ROOT/config/zsh/"*.zsh "$ROOT/shell/zsh/"*; do zsh -n "$file"; done
while IFS= read -r -d '' file; do fish -n "$file"; done < <(find "$ROOT/config/fish" -type f -name '*.fish' -print0)
if command -v nvim >/dev/null; then
    check_scratch="$(mktemp -d)"
    trap 'rm -rf -- "$check_scratch"' EXIT
    DOTFILES_CHECK_ROOT="$ROOT" XDG_CONFIG_HOME="$check_scratch/config" XDG_DATA_HOME="$check_scratch/data" \
        XDG_STATE_HOME="$check_scratch/state" XDG_CACHE_HOME="$check_scratch/cache" \
        nvim --headless -u NONE -i NONE \
            -c 'lua dofile(vim.env.DOTFILES_CHECK_ROOT .. "/scripts/check-lua.lua")' -c 'qa!'
else
    printf 'Skipped Lua syntax check: Neovim is unavailable.\n'
fi
