#!/bin/bash

echo "=== Testing OSC52 workaround for Zellij ==="
echo

# Test using cat with temp file (same method as our Neovim workaround)
test_workaround() {
    local text="$1"
    local b64=$(echo -n "$text" | base64)
    local osc52=$(printf '\033]52;c;%s\007' "$b64")
    
    echo "Testing: $text"
    
    # Method 1: Direct (might fail in Zellij)
    echo "Method 1: Direct write to stderr"
    printf '%s' "$osc52" >&2
    
    # Method 2: Using temp file + cat (workaround)
    echo "Method 2: Temp file + cat"
    tmpfile=$(mktemp)
    printf '%s' "$osc52" > "$tmpfile"
    cat "$tmpfile" >&2
    rm "$tmpfile"
    
    echo "Sent. Try pasting..."
    echo
}

echo "Environment:"
echo "  In SSH: ${SSH_CONNECTION:+Yes}"
echo "  In Zellij: ${ZELLIJ:+Yes}"
echo "  In tmux: ${TMUX:+Yes}"
echo

test_workaround "Zellij_workaround_test"

echo "If the workaround works, commit and sync the changes:"
echo "  git add -A"
echo "  git commit -m 'Fix OSC52 clipboard for Zellij over SSH'"
echo "  git push origin amal"
echo
echo "Then on krsn: git pull origin amal"