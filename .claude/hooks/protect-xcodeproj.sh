#!/bin/bash
# PreToolUse hook: block direct edits to .xcodeproj (edit project.yml instead)
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.content // empty')

if [[ "$FILE_PATH" == *.xcodeproj* ]] || [[ "$FILE_PATH" == *.pbxproj* ]]; then
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Cannot edit .xcodeproj directly — it is generated. Edit project.yml instead, then run xcodegen generate."}}'
  exit 0
fi

exit 0
