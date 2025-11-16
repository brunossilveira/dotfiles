#!/bin/bash

# Claude Code standalone session note script
# Creates individual markdown notes for Claude Code sessions
# Logs to Obsidian vault with full YAML frontmatter

# Enable debug logging
DEBUG_LOG="$HOME/Documents/claude-session-debug.log"
exec 2>> "$DEBUG_LOG"
set -x

echo "=== Session Note Debug - $(date) ===" >> "$DEBUG_LOG"

VAULT_DIR="${OBSIDIAN_VAULT_DIR:-/Volumes/NAS/bruno/vault}"
DATE_ONLY=$(date "+%Y-%m-%d")
TRANSCRIPT_DIR="$HOME/Documents/claude-transcripts"
TIMESTAMP=$(date "+%Y-%m-%d_%H-%M-%S")
DATE_DISPLAY=$(date "+%Y-%m-%d %H:%M:%S")
PROJECT_DIR="${PWD}"
PROJECT_NAME=$(basename "${PROJECT_DIR}")

echo "VAULT_DIR: $VAULT_DIR" >> "$DEBUG_LOG"
echo "PROJECT_NAME: $PROJECT_NAME" >> "$DEBUG_LOG"
echo "PROJECT_DIR: $PROJECT_DIR" >> "$DEBUG_LOG"

# Create directories if they don't exist
mkdir -p "$TRANSCRIPT_DIR" 2>> "$DEBUG_LOG"
mkdir -p "$VAULT_DIR" 2>> "$DEBUG_LOG"

# Test write permissions
if [ ! -w "$VAULT_DIR" ]; then
    echo "ERROR: No write permission to $VAULT_DIR" >> "$DEBUG_LOG"
    echo "ERROR: Cannot write to vault directory: $VAULT_DIR"
    exit 1
fi

# Save transcript if available
TRANSCRIPT_FILE="$TRANSCRIPT_DIR/${PROJECT_NAME}_${TIMESTAMP}.md"
if [ -n "$CLAUDE_TRANSCRIPT" ]; then
    echo "Saving transcript to: $TRANSCRIPT_FILE" >> "$DEBUG_LOG"
    cat > "$TRANSCRIPT_FILE" << EOF
# Claude Code Session Transcript

**Project:** $PROJECT_NAME
**Directory:** $PROJECT_DIR
**Date:** $DATE_DISPLAY

---

$CLAUDE_TRANSCRIPT
EOF
fi

# Read session content from stdin
echo "Reading session content from stdin..." >> "$DEBUG_LOG"
if [ -t 0 ]; then
    # stdin is a terminal, no piped input
    echo "ERROR: No input provided" >> "$DEBUG_LOG"
    echo "ERROR: This script expects input to be piped in"
    exit 1
else
    # Read all content from stdin
    SESSION_CONTENT=$(cat)
    if [ -z "$SESSION_CONTENT" ]; then
        echo "ERROR: Empty input received" >> "$DEBUG_LOG"
        echo "ERROR: No session content provided"
        exit 1
    fi
    echo "Content received (${#SESSION_CONTENT} chars)" >> "$DEBUG_LOG"
fi

# Parse the session content
# Expected format:
# **Title:** short-title-slug
# **Tags:** #tag1, #tag2
# **Summary:** The summary text...

# Extract title (fallback to project name if not found)
TITLE=$(echo "$SESSION_CONTENT" | grep -i "^\*\*Title:\*\*" | sed 's/^\*\*Title:\*\* *//' | head -1)
if [ -z "$TITLE" ]; then
    echo "No title found, using project name" >> "$DEBUG_LOG"
    TITLE=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr '_' '-')
fi
echo "Title: $TITLE" >> "$DEBUG_LOG"

# Extract tags (fallback to empty if not found)
TAGS=$(echo "$SESSION_CONTENT" | grep -i "^\*\*Tags:\*\*" | sed 's/^\*\*Tags:\*\* *//' | head -1)
echo "Tags: $TAGS" >> "$DEBUG_LOG"

# Extract summary (everything after Summary: line)
SUMMARY=$(echo "$SESSION_CONTENT" | sed -n '/^\*\*Summary:\*\*/,$p' | sed 's/^\*\*Summary:\*\* *//' | sed '1s/^[[:space:]]*//')
if [ -z "$SUMMARY" ]; then
    SUMMARY="$SESSION_CONTENT"
fi
echo "Summary extracted (${#SUMMARY} chars)" >> "$DEBUG_LOG"

# Create filename
NOTE_FILE="$VAULT_DIR/${DATE_ONLY}-claude-session-${TITLE}.md"
echo "Creating note file: $NOTE_FILE" >> "$DEBUG_LOG"

# Build tags array for YAML frontmatter
TAG_ARRAY="  - claude-sessions"
if [ -n "$TAGS" ]; then
    # Convert #tag1, #tag2 format to YAML array
    for tag in $(echo "$TAGS" | tr ',' '\n' | sed 's/#//g' | sed 's/^[[:space:]]*//'); do
        if [ -n "$tag" ]; then
            TAG_ARRAY="$TAG_ARRAY"$'\n'"  - $tag"
        fi
    done
fi

# Create the note file
cat > "$NOTE_FILE" << EOF
---
date: $DATE_ONLY
type: claude-session
project: $PROJECT_NAME
tags:
$TAG_ARRAY
created: $DATE_DISPLAY
---

# Claude Session: $TITLE

**Project:** $PROJECT_NAME
**Directory:** \`$PROJECT_DIR\`
**Date:** $DATE_DISPLAY
EOF

# Add transcript link if available
if [ -f "$TRANSCRIPT_FILE" ]; then
    echo "**Transcript:** [\`${PROJECT_NAME}_${TIMESTAMP}.md\`](file://$TRANSCRIPT_FILE)  " >> "$NOTE_FILE"
fi

# Add summary
cat >> "$NOTE_FILE" << EOF

## Summary

$SUMMARY
EOF

if [ $? -eq 0 ]; then
    echo "Session note created successfully: $NOTE_FILE" >> "$DEBUG_LOG"
    echo "Session note created: $(basename "$NOTE_FILE")"
else
    echo "ERROR: Failed to create note file" >> "$DEBUG_LOG"
    echo "ERROR: Failed to create session note"
    exit 1
fi

echo "=== Session Note Complete ===" >> "$DEBUG_LOG"
echo "" >> "$DEBUG_LOG"
