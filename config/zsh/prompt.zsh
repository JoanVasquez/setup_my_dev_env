# Starship owns the prompt; virtualenv should not prepend a second environment label.
export VIRTUAL_ENV_DISABLE_PROMPT=1
FUNCNEST=100
if (( $+commands[starship] )); then eval "$(command starship init zsh)"; fi
