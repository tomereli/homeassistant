#!/bin/bash
cd ~/homeassistant

# Stage only parent repo files (not submodule)
git add docker-compose.yml .gitignore git-backup.sh

# Check if there are changes
if git diff --cached --quiet; then
    exit 0
fi

# Get diff for AI commit message
DIFF=$(git diff --cached --stat)

# Call Gemini API for commit message
API_KEY="REDACTED"
PROMPT="Generate a concise git commit message (max 72 chars) for these changes. No quotes. Changes: $DIFF"

RESPONSE=$(curl -s "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"contents\":[{\"parts\":[{\"text\":\"$PROMPT\"}]}]}" 2>/dev/null)

# Extract message from response
MESSAGE=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['candidates'][0]['content']['parts'][0]['text'].strip())" 2>/dev/null)

# Fallback if AI fails
if [ -z "$MESSAGE" ]; then
    MESSAGE="Auto-backup parent repo"
fi

git commit -m "$MESSAGE"
git push origin main
