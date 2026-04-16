#!/bin/bash
# flow-abc sync — Compile .ai/rules/ → .github/copilot-instructions.md
#
# Usage: bash sync.sh [project-root]
# If no argument, uses current directory.

set -e

PROJECT_ROOT="${1:-.}"
RULES_DIR="$PROJECT_ROOT/.ai/rules"
OUTPUT_DIR="$PROJECT_ROOT/.github"
OUTPUT_FILE="$OUTPUT_DIR/copilot-instructions.md"

# Check if .ai/rules/ exists
if [ ! -d "$RULES_DIR" ]; then
  echo "❌ Error: $RULES_DIR not found. Run init first."
  exit 1
fi

# Create .github/ if needed
mkdir -p "$OUTPUT_DIR"

# Write header
cat > "$OUTPUT_FILE" << 'EOF'
# AI Development Rules

<!-- Auto-generated from .ai/rules/. Edit source files, then recompile with sync. -->

EOF

# Compile all rule files except review.md
FOUND=0
for f in "$RULES_DIR"/*.md; do
  [ -f "$f" ] || continue
  BASENAME=$(basename "$f")
  
  # Skip review.md — it's loaded on-demand, not compiled
  if [ "$BASENAME" = "review.md" ]; then
    continue
  fi
  
  cat "$f" >> "$OUTPUT_FILE"
  echo -e "\n---\n" >> "$OUTPUT_FILE"
  FOUND=$((FOUND + 1))
done

if [ "$FOUND" -eq 0 ]; then
  echo "⚠️  No rule files found in $RULES_DIR (excluding review.md)"
  exit 1
fi

echo "✅ Compiled $FOUND rule file(s) → $OUTPUT_FILE"
