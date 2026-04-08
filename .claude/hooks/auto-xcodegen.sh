#!/bin/bash
# PostToolUse hook: auto-run xcodegen generate after Swift file creation/deletion
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ "$FILE_PATH" == *.swift ]]; then
  cd "$CLAUDE_PROJECT_DIR" 2>/dev/null || exit 0
  xcodegen generate 2>/dev/null
fi

exit 0
