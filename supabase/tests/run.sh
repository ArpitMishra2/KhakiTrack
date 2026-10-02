#!/usr/bin/env bash
# Runs a SQL test file against the dev project through the Management API.
# Tests end by raising "PASS ..." or "FAIL ...", which rolls back their data.
# Needs SUPABASE_ACCESS_TOKEN (a personal access token) and node.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
ref="${SUPABASE_PROJECT_REF:-kduqwkutzyxljhlktuwi}"
body="$(node -e "process.stdout.write(JSON.stringify({query: require('fs').readFileSync(process.argv[1], 'utf8')}))" "$here/$1")"
out="$(curl -s -X POST "https://api.supabase.com/v1/projects/$ref/database/query" \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  --data-binary "$body")"
echo "$out"
case "$out" in
  *"PASS "*) exit 0 ;;
  *) exit 1 ;;
esac
