#!/bin/bash
# flow-abc sync — Compile .ai/rules/ → .github/copilot-instructions.md
#                 For monorepos, also compile .ai-<name>/rules/ → .github/instructions/<name>.instructions.md
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

# --- Monorepo: compile path-specific instructions ---

INSTRUCTIONS_DIR="$OUTPUT_DIR/instructions"
SUB_COUNT=0

for SUB_DIR in "$PROJECT_ROOT"/.ai-*/; do
  [ -d "$SUB_DIR/rules" ] || continue

  NAME=$(basename "$SUB_DIR")
  NAME="${NAME#.ai-}"

  # Read applyTo glob from file, default to "**"
  APPLY_TO="**"
  if [ -f "$SUB_DIR/applyTo" ]; then
    APPLY_TO=$(cat "$SUB_DIR/applyTo")
  fi

  mkdir -p "$INSTRUCTIONS_DIR"
  SUB_OUTPUT="$INSTRUCTIONS_DIR/${NAME}.instructions.md"

  # Write frontmatter + header
  cat > "$SUB_OUTPUT" << EOF
---
applyTo: "$APPLY_TO"
---

<!-- Auto-generated from .ai-${NAME}/rules/. Edit source files, then recompile with sync. -->

EOF

  # Append all rule files except review.md
  SUB_FOUND=0
  for f in "$SUB_DIR/rules/"*.md; do
    [ -f "$f" ] || continue
    BASENAME=$(basename "$f")
    if [ "$BASENAME" = "review.md" ]; then
      continue
    fi
    cat "$f" >> "$SUB_OUTPUT"
    echo -e "\n---\n" >> "$SUB_OUTPUT"
    SUB_FOUND=$((SUB_FOUND + 1))
  done

  if [ "$SUB_FOUND" -gt 0 ]; then
    echo "✅ Compiled $SUB_FOUND rule file(s) → $SUB_OUTPUT (applyTo: $APPLY_TO)"
    SUB_COUNT=$((SUB_COUNT + 1))
  else
    rm -f "$SUB_OUTPUT"
  fi
done

if [ "$SUB_COUNT" -gt 0 ]; then
  echo "📦 Monorepo: compiled $SUB_COUNT sub-project instruction(s)"
fi
