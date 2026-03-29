#!/bin/bash
cd ~/homeassistant
python3 -c "
import json

REDACT_KEYS = {'bottoken', 'token', 'key', 'secret', 'password', 'apikey', 'hasstoken'}

redacted_values = []

def redact(obj):
    if isinstance(obj, dict):
        for k, v in obj.items():
            if k.lower().replace('_','') in REDACT_KEYS:
                if isinstance(v, str) and len(v) > 8:
                    redacted_values.append(v)
                    obj[k] = v[:4] + '***REDACTED***'
            else:
                redact(v)
    elif isinstance(obj, list):
        for item in obj:
            redact(item)

with open('openclaw-data/openclaw.json', 'r') as f:
    c = json.load(f)

redact(c)

with open('openclaw.config.bkp', 'w') as f:
    json.dump(c, f, indent=2)

# Verify none of the redacted values appear in output
with open('openclaw.config.bkp', 'r') as f:
    content = f.read()

leaked = [v for v in redacted_values if v in content]
if leaked:
    print(f'ERROR: {len(leaked)} secret(s) still in redacted file!')
    exit(1)

print(f'OK: Redacted {len(redacted_values)} secret(s), none leaked')
print('Redacted keys found:')
for v in redacted_values:
    print(f'  {v[:4]}...({len(v)} chars)')
"
