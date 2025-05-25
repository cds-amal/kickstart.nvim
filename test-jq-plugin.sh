#!/bin/bash
cd /Users/amal/.config/nvim

# Test basic functionality
nvim -u NONE \
  -c "set rtp+=." \
  -c "runtime! plugin/**/*.vim" \
  -c "lua require('custom.plugins.jq-treesitter.init').setup()" \
  -c "edit lua/custom/plugins/jq-treesitter/test-data.json" \
  -c "JqtList" \
  -c "sleep 1" \
  -c "cclose" \
  -c "echo 'Plugin loaded successfully!'" \
  -c "qa!"