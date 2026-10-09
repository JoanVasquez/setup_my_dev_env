#!/usr/bin/env bash
# Window indices start at one. Avoid arithmetic on untrusted/huge indices.
icons=(󰎦 󰎩 󰎬 󰎮 󰎰 󰎵 󰎸 󰎻 󰎾)
[[ $# == 1 && "$1" =~ ^[1-9][0-9]*$ ]] || exit 1
case "$1" in
    [1-9]) printf ' %s ' "${icons[$1-1]}" ;;
    *) printf ' %s ' "$1" ;;
esac
