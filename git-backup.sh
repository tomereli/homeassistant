#!/bin/bash
#
# Smart Home Git Backup Script
#
# Usage:
#   ./git-backup.sh                                     Auto-commit with Gemini-generated message
#   ./git-backup.sh --dry-run                            Preview changes and AI message (no commit)
#   ./git-backup.sh --skip-ai -m "my message"           Commit with inline message
#   ./git-backup.sh --skip-ai --file /tmp/msg.txt       Commit with message from file
#   ./git-backup.sh --dry-run --skip-ai --file msg.txt  Preview with file message
#   ./git-backup.sh --help                               Show this help
#
# Called nightly by HA automation at 3:17 AM (no flags = AI message).
# Use --skip-ai for manual commits where you want to control the message.
# Use --dry-run to verify what will be committed before pushing.
#
# The script also generates openclaw.config.bkp (sanitized OpenClaw config
# with secrets stripped) via redact-openclaw-config.sh before each commit.
#

cd ~/homeassistant

# Help
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Smart Home Git Backup Script"
    echo ""
    echo "Usage:"
    echo "  ./git-backup.sh                                     Auto-commit with Gemini-generated message"
    echo "  ./git-backup.sh --dry-run                            Preview changes (no commit)"
    echo "  ./git-backup.sh --skip-ai -m \"my message\"           Commit with inline message"
    echo "  ./git-backup.sh --skip-ai --file /tmp/msg.txt       Commit with message from file"
    echo "  ./git-backup.sh --dry-run --skip-ai --file msg.txt  Preview with file message"
    echo ""
    echo "Options:"
    echo "  --dry-run    Show staged files and commit message without committing"
    echo "  --skip-ai    Use manual message instead of Gemini AI"
    echo "  --file PATH  Read commit message from file (use with --skip-ai)"
    echo "  -m MESSAGE   Inline commit message (use with --skip-ai)"
    echo "  -h, --help   Show this help"
    exit 0
fi

# Generate sanitized openclaw config backup
./redact-openclaw-config.sh

# Stage all tracked files + new ones
git add docker-compose.yml .gitignore git-backup.sh redact-openclaw-config.sh openclaw.config.bkp config dashboard/ README.md

# Check if there are changes
if git diff --cached --quiet; then
    echo "No changes to commit"
    exit 0
fi

# Parse args
DRY_RUN=false
SKIP_AI=false
MSG_FILE=""
INLINE_MSG=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run) DRY_RUN=true; shift ;;
        --skip-ai) SKIP_AI=true; shift ;;
        --file) MSG_FILE="$2"; shift 2 ;;
        -m) INLINE_MSG="$2"; shift 2 ;;
        *) shift ;;
    esac
done

# Build commit message
if [ "$SKIP_AI" = true ]; then
    if [ -n "$MSG_FILE" ]; then
        MESSAGE=$(cat "$MSG_FILE")
    elif [ -n "$INLINE_MSG" ]; then
        MESSAGE="$INLINE_MSG"
    else
        MESSAGE="Manual backup"
    fi
else
    DIFF=$(git diff --cached --stat)
    API_KEY=$(docker exec homeassistant cat /config/.storage/core.config_entries | python3 -c "
import sys,json
data = json.load(sys.stdin)
for entry in data['data']['entries']:
    if entry['domain'] == 'google_generative_ai_conversation':
        print(entry['data']['api_key'])
        break
" 2>/dev/null)

    if [ -z "$API_KEY" ]; then
        MESSAGE="Auto-backup"
    else
        PROMPT="Generate a concise git commit message (max 72 chars) for these changes. No quotes. Changes: $DIFF"
        RESPONSE=$(curl -s "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$API_KEY" \
          -H "Content-Type: application/json" \
          -d "{\"contents\":[{\"parts\":[{\"text\":\"$PROMPT\"}]}]}" 2>/dev/null)
        MESSAGE=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['candidates'][0]['content']['parts'][0]['text'].strip())" 2>/dev/null)
        if [ -z "$MESSAGE" ]; then
            MESSAGE="Auto-backup"
        fi
    fi
fi

# Dry run or commit
if [ "$DRY_RUN" = true ]; then
    echo "=== DRY RUN ==="
    echo ""
    echo "Files:"
    git diff --cached --stat
    echo ""
    echo "Commit message:"
    echo "$MESSAGE"
    echo ""
    echo "=== Run without --dry-run to commit ==="
    git reset HEAD -- . > /dev/null 2>&1
    exit 0
fi

git commit -m "$MESSAGE"
git push origin main
