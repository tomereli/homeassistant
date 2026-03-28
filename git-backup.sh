#!/bin/bash
cd ~/homeassistant

# Stage parent repo files + submodule pointer
git add docker-compose.yml .gitignore git-backup.sh config

# Check if there are changes
if git diff --cached --quiet; then
    exit 0
fi

# Get diff for AI commit message
DIFF=$(git diff --cached)

# Read API key from HA config (already stored there)
API_KEY=$(docker exec homeassistant cat /config/.storage/core.config_entries | python3 -c "
import sys,json
data = json.load(sys.stdin)
for entry in data['data']['entries']:
    if entry['domain'] == 'google_generative_ai_conversation':
        print(entry['data']['api_key'])
        break
" 2>/dev/null)

if [ -z "$API_KEY" ]; then
    MESSAGE="Auto-backup parent repo"
else
    PROMPT="Generate a concise git commit message (max 72 chars) for these changes. No quotes. Changes: $DIFF"
    RESPONSE=$(curl -s "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$API_KEY" \
      -H "Content-Type: application/json" \
      -d "{\"contents\":[{\"parts\":[{\"text\":\"$PROMPT\"}]}]}" 2>/dev/null)
    MESSAGE=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['candidates'][0]['content']['parts'][0]['text'].strip())" 2>/dev/null)
    if [ -z "$MESSAGE" ]; then
        MESSAGE="Auto-backup parent repo"
    fi
fi

git commit -m "$MESSAGE"
git push origin main
