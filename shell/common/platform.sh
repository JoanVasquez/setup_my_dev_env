# Distro aliases use the same token-based detector as the installer.
case "$(os_family)" in
    arch)
        alias update='sudo pacman -Syu'
        alias install='sudo pacman -S'
        alias remove='sudo pacman -Rns' ;;
    debian)
        alias update='sudo apt update && sudo apt upgrade'
        alias install='sudo apt install'
        alias remove='sudo apt remove' ;;
esac
# Debian calls these executables batcat and fdfind.
if ! command -v bat >/dev/null 2>&1 && command -v batcat >/dev/null 2>&1; then alias bat=batcat; fi
if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then alias fd=fdfind; fi
