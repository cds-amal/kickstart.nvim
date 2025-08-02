#!/bin/bash

echo "=== Environment Debug for SSH + Zellij ==="
echo

echo "Current environment:"
echo "SSH_CONNECTION: ${SSH_CONNECTION:-not set}"
echo "SSH_TTY: ${SSH_TTY:-not set}"
echo "ZELLIJ: ${ZELLIJ:-not set}"
echo "ZELLIJ_SESSION_NAME: ${ZELLIJ_SESSION_NAME:-not set}"
echo "TMUX: ${TMUX:-not set}"
echo "TERM: $TERM"
echo

echo "Testing OSC52 in current environment..."
text="Test_$(date +%s)"
b64=$(echo -n "$text" | base64)
printf '\033]52;c;%s\007' "$b64" >&2
echo "Sent: $text"
echo "Try pasting now..."
echo

echo "Creating Neovim test..."
cat > /tmp/test_env.vim << 'EOF'
echo "Neovim environment:"
echo "SSH_CONNECTION: " . $SSH_CONNECTION
echo "ZELLIJ: " . $ZELLIJ
echo "Clipboard: " . &clipboard
echo ""
echo "Testing yank..."
call setline(1, "Test from Neovim")
normal! yy
echo "Yanked. Try pasting."
EOF

echo "Run: nvim -S /tmp/test_env.vim"