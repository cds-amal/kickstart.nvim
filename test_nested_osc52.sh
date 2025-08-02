#!/bin/bash

echo "=== Testing OSC52 in nested terminal sessions ==="
echo

# Test function
test_osc52() {
    local context="$1"
    local text="Test_${context}_$(date +%s)"
    local b64=$(echo -n "$text" | base64)
    
    echo "[$context]"
    echo "Sending: $text"
    
    # Try different OSC52 formats
    printf '\033]52;c;%s\007' "$b64" >&2
    
    echo "Sent. Try pasting..."
    echo
}

# Test 1: Direct
test_osc52 "Direct"

# Show instructions
echo "To test different scenarios:"
echo
echo "1. Direct SSH (working):"
echo "   ssh krsn"
echo "   ~/.config/nvim/test_nested_osc52.sh"
echo
echo "2. SSH + Zellij (not working):"
echo "   ssh krsn"
echo "   zellij"
echo "   ~/.config/nvim/test_nested_osc52.sh"
echo
echo "3. Check Zellij config on krsn:"
echo "   cat ~/.config/zellij/config.kdl | grep -i clip"
echo
echo "The issue is likely that Zellij needs to be configured to pass through OSC52."