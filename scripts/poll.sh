#!/usr/bin/env bash
# Kinetra poller for GitHub Actions: poll active jobs, notify Telegram on new ones.
set -u

export PATH="$HOME/.nvm/versions/node/v24.13.0/bin:$HOME/.local/acp/bin:/usr/local/bin:$PATH"
# Node is already on PATH in GitHub runners, but ensure acp is findable
if ! command -v acp &>/dev/null; then
  export PATH="/usr/local/lib/node_modules/.bin:$PATH"
fi

STATE_FILE="state/known_jobs.json"
TG_TOKEN="${TG_TOKEN:-}"
TG_CHAT="${TG_CHAT:-}"

mkdir -p state
if [ ! -f "$STATE_FILE" ]; then
  echo '{"job_ids":[],"last_check":""}' > "$STATE_FILE"
fi

# Poll active jobs
JOBS_JSON=$(acp job list --all --json 2>/dev/null) || JOBS_JSON=""

if [ -z "$JOBS_JSON" ]; then
  echo "No response from ACP server (possibly down). Skipping."
  exit 0
fi

# Parse and compare with Python
python3 - "$JOBS_JSON" "$STATE_FILE" "$TG_TOKEN" "$TG_CHAT" <<'PYEOF'
import json, sys, subprocess, datetime

jobs_json = sys.argv[1]
state_file = sys.argv[2]
tg_token = sys.argv[3]
tg_chat = sys.argv[4]

try:
    data = json.loads(jobs_json)
except Exception as e:
    print(f"JSON parse error: {e}")
    sys.exit(0)

# acp job list returns a list or {"data": [...]}
if isinstance(data, list):
    jobs = data
elif isinstance(data, dict):
    jobs = data.get("data") or data.get("jobs") or []
else:
    jobs = []

# Extract job IDs
current_ids = []
for j in jobs:
    jid = j.get("jobId") or j.get("id") or j.get("onChainJobId")
    if jid:
        current_ids.append(str(jid))

# Load known state
try:
    with open(state_file) as f:
        state = json.load(f)
except Exception:
    state = {"job_ids": [], "last_check": ""}

known_ids = set(state.get("job_ids", []))

# Find new jobs
new_jobs = [jid for jid in current_ids if jid not in known_ids]

# Send Telegram notification for each new job
for jid in new_jobs:
    # Find job details
    detail = ""
    for j in jobs:
        if str(j.get("jobId") or j.get("id") or j.get("onChainJobId")) == jid:
            detail = f"Status: {j.get('status','?')}"
            break
    msg = f"🔔 Kinetra — Nuevo job detectado\nJob: {jid}\n{detail}"
    if tg_token and tg_chat:
        try:
            subprocess.run(
                ["curl", "-s", "-X", "POST",
                 f"https://api.telegram.org/bot{tg_token}/sendMessage",
                 "-d", f"chat_id={tg_chat}",
                 "-d", f"text={msg}"],
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=15
            )
            print(f"Notified: {jid}")
        except Exception as e:
            print(f"Telegram error: {e}")

# Update state
state["job_ids"] = current_ids
state["last_check"] = datetime.datetime.now(datetime.timezone.utc).isoformat()
with open(state_file, "w") as f:
    json.dump(state, f, indent=2)

print(f"Checked {len(current_ids)} active jobs, {len(new_jobs)} new.")
PYEOF