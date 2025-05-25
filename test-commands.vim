" Quick test of jq-treesitter commands
" Run with :source %

echo "Testing jq-treesitter plugin..."

" Test 1: JqtList
echo "\n1. Running JqtList..."
JqtList
echo "   ✓ Should show quickfix with 7 keys"

" Test 2: JqtQuery with simple path
echo "\n2. Testing JqtQuery .abi"
JqtQuery .abi
echo "   ✓ Should show floating window with ABI array"

" Test 3: JqtQuery with complex filter
echo "\n3. Testing JqtQuery .abi[] | {name, type}"
JqtQuery .abi[] | {name, type}
echo "   ✓ Should show filtered ABI entries"

" Test 4: Get path at cursor
echo "\n4. Place cursor on a value and run:"
echo "   :JqtPath or press ,jcp"
echo "   ✓ Should copy JSON path to clipboard"

" Test 5: Markdown table
echo "\n5. Place cursor inside an array/object and run:"
echo "   :JqtMarkdownTable or press ,jmt"
echo "   ✓ Should copy markdown table to clipboard"

echo "\nAll commands registered successfully!"