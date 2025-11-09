#!/bin/bash

# Claude Code session logging script
# Captures full session transcripts and creates compressed summaries
# Logs to daily Obsidian vault files

# Enable debug logging
DEBUG_LOG="$HOME/Documents/claude-session-debug.log"
exec 2>> "$DEBUG_LOG"
set -x

echo "=== Session Log Debug - $(date) ===" >> "$DEBUG_LOG"

VAULT_DIR="${OBSIDIAN_VAULT_DIR:-/Volumes/NAS/bruno/vault}"
DATE_ONLY=$(date "+%Y-%m-%d")
LOG_FILE="$VAULT_DIR/${DATE_ONLY}-work-log.md"
TRANSCRIPT_DIR="$HOME/Documents/claude-transcripts"
TIMESTAMP=$(date "+%Y-%m-%d_%H-%M-%S")
TIME_DISPLAY=$(date "+%H:%M:%S")
DATE_DISPLAY=$(date "+%Y-%m-%d %H:%M:%S")
PROJECT_DIR="${PWD}"
PROJECT_NAME=$(basename "${PROJECT_DIR}")

echo "VAULT_DIR: $VAULT_DIR" >> "$DEBUG_LOG"
echo "LOG_FILE: $LOG_FILE" >> "$DEBUG_LOG"
echo "PROJECT_NAME: $PROJECT_NAME" >> "$DEBUG_LOG"
echo "PROJECT_DIR: $PROJECT_DIR" >> "$DEBUG_LOG"

# Create directories if they don't exist
echo "Creating directories..." >> "$DEBUG_LOG"
mkdir -p "$TRANSCRIPT_DIR" 2>> "$DEBUG_LOG"
echo "Transcript dir created: $TRANSCRIPT_DIR" >> "$DEBUG_LOG"

mkdir -p "$VAULT_DIR" 2>> "$DEBUG_LOG"
echo "Vault dir created/checked: $VAULT_DIR" >> "$DEBUG_LOG"

# Test write permissions
if [ ! -w "$VAULT_DIR" ]; then
    echo "ERROR: No write permission to $VAULT_DIR" >> "$DEBUG_LOG"
    echo "ERROR: Cannot write to vault directory: $VAULT_DIR"
    exit 1
fi

echo "Vault directory is writable" >> "$DEBUG_LOG"

# Create daily log file with YAML front matter if it doesn't exist
echo "Checking for existing log file: $LOG_FILE" >> "$DEBUG_LOG"
if [ ! -f "$LOG_FILE" ]; then
    echo "Creating new daily log file..." >> "$DEBUG_LOG"
    cat > "$LOG_FILE" << EOF
---
date: $DATE_ONLY
type: work-log
tags:
  - claude-sessions
  - daily-log
created: $DATE_DISPLAY
---

# Work Log - $DATE_ONLY

## Claude Code Sessions

EOF
    echo "Daily log file created successfully" >> "$DEBUG_LOG"
else
    echo "Daily log file already exists" >> "$DEBUG_LOG"
fi

# Capture the session transcript if available
# The CLAUDE_TRANSCRIPT environment variable contains the session content
TRANSCRIPT_FILE="$TRANSCRIPT_DIR/${PROJECT_NAME}_${TIMESTAMP}.md"

echo "Checking for transcript in CLAUDE_TRANSCRIPT variable..." >> "$DEBUG_LOG"
if [ -n "$CLAUDE_TRANSCRIPT" ]; then
    echo "Transcript found, saving to: $TRANSCRIPT_FILE" >> "$DEBUG_LOG"
    cat > "$TRANSCRIPT_FILE" << EOF
# Claude Code Session Transcript

**Project:** $PROJECT_NAME
**Directory:** $PROJECT_DIR
**Date:** $DATE_DISPLAY

---

$CLAUDE_TRANSCRIPT
EOF
    echo "Transcript saved successfully" >> "$DEBUG_LOG"
else
    echo "No transcript available in CLAUDE_TRANSCRIPT" >> "$DEBUG_LOG"
fi

# Get summary from stdin (provided by Claude Code hook) or use default
echo "Reading summary from stdin..." >> "$DEBUG_LOG"
# Read all available input from stdin (multi-line support)
if [ -t 0 ]; then
    # stdin is a terminal, no piped input
    echo "No stdin available (terminal), checking CLAUDE_SUMMARY env var..." >> "$DEBUG_LOG"
    SESSION_SUMMARY="${CLAUDE_SUMMARY:-Session completed for $PROJECT_NAME}"
    echo "Using summary: $SESSION_SUMMARY" >> "$DEBUG_LOG"
else
    # stdin is piped, read all lines
    echo "Reading from piped stdin..." >> "$DEBUG_LOG"
    SESSION_SUMMARY=$(cat)
    if [ -n "$SESSION_SUMMARY" ]; then
        echo "Summary received from stdin (${#SESSION_SUMMARY} chars)" >> "$DEBUG_LOG"
    else
        echo "Empty stdin, using default" >> "$DEBUG_LOG"
        SESSION_SUMMARY="Session completed for $PROJECT_NAME"
    fi
fi

# If still empty, use a default
if [ -z "$SESSION_SUMMARY" ]; then
    SESSION_SUMMARY="Session completed for $PROJECT_NAME"
    echo "No summary provided, using default" >> "$DEBUG_LOG"
fi

# Append to daily log file
echo "Appending session to log file..." >> "$DEBUG_LOG"
{
    echo ""
    echo "### $PROJECT_NAME - $TIME_DISPLAY"
    echo ""
    if [ -f "$TRANSCRIPT_FILE" ]; then
        echo "**Transcript:** [\`${PROJECT_NAME}_${TIMESTAMP}.md\`](file://$TRANSCRIPT_FILE)  "
    fi
    echo "**Summary:** $SESSION_SUMMARY"
    echo ""
} >> "$LOG_FILE" 2>> "$DEBUG_LOG"

if [ $? -eq 0 ]; then
    echo "Session entry appended successfully" >> "$DEBUG_LOG"
else
    echo "ERROR: Failed to append to log file" >> "$DEBUG_LOG"
fi

# Log completion silently to debug log only
echo "Session logged to $LOG_FILE" >> "$DEBUG_LOG"
if [ -f "$TRANSCRIPT_FILE" ]; then
    echo "Full transcript saved to $TRANSCRIPT_FILE" >> "$DEBUG_LOG"
fi

echo "=== Session Log Complete ===" >> "$DEBUG_LOG"
echo "" >> "$DEBUG_LOG"
