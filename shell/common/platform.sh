# All shells use the same package aliases and token-based distro detector.
dotfiles_alias_family="$(os_family)"
while IFS=$'\t' read -r dotfiles_alias_name dotfiles_alias_arch dotfiles_alias_debian dotfiles_alias_fedora; do
    [[ -n "$dotfiles_alias_name" && "$dotfiles_alias_name" != \#* ]] || continue
    case "$dotfiles_alias_family" in
        arch) alias "$dotfiles_alias_name=$dotfiles_alias_arch" ;;
        debian) alias "$dotfiles_alias_name=$dotfiles_alias_debian" ;;
        fedora) alias "$dotfiles_alias_name=$dotfiles_alias_fedora" ;;
    esac
done < "$DOTFILES_HOME/shell/common/package-aliases.tsv"
unset dotfiles_alias_family dotfiles_alias_name dotfiles_alias_arch dotfiles_alias_debian dotfiles_alias_fedora
# Debian calls these executables batcat and fdfind.
if ! command -v bat >/dev/null 2>&1 && command -v batcat >/dev/null 2>&1; then alias bat=batcat; fi
if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then alias fd=fdfind; fi
