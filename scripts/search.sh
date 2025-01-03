#!/usr/bin/env bash

# 1. Search for text in files using Ripgrep
# 2. Interactively narrow down the list using fzf
# 3. Open the file in Vim
rg --line-number --no-heading --smart-case "${*:-}" |
  fzf --ansi \
    --color "hl:-1:underline,hl+:-1:underline:reverse" \
    --delimiter : \
    --preview 'bat  --style=numbers --color=always {1} --highlight-line {2}' \
    --preview-window 'up,+{2}+3/3,~3' \
