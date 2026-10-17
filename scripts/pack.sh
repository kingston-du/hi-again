#!/bin/bash
# Usage: scripts/pack.sh <CARD_ID>   e.g. scripts/pack.sh B2
# Copies AGENTS.md, PLAN.md Part 3, the card, and every file the card lists to the clipboard.
set -euo pipefail
cd "$(dirname "$0")/.."
id="${1:?usage: scripts/pack.sh <CARD_ID>}"

card=$(awk -v id="$id" '
  index($0, "**" id " · ") == 1 { f = 1 }
  f && /^\*\*[AB][0-9]+ · / && index($0, "**" id " · ") != 1 { exit }
  f && /^(### |> \*\*CHECKPOINT)/ { exit }
  f { print }' docs/TASKS.md)
[ -n "$card" ] || { echo "No card $id in docs/TASKS.md" >&2; exit 1; }

# Paths in backticks on the Files: part of the card, e.g. `supabase/schema.sql` or `Services/SupabaseService.swift`
files=$(printf '%s\n' "$card" | head -1 | sed -n 's/.*Files: \(.*\) · \*Done when.*/\1/p' | grep -oE '`[^`]+`' | tr -d '`' || true)

{
  echo "===== AGENTS.md ====="; cat AGENTS.md; echo
  echo "===== docs/PLAN.md Part 3 (contracts) ====="
  awk '/^## Part 3\./{f=1} /^## Part 4\./{f=0} f' docs/PLAN.md; echo
  echo "===== Card $id (docs/TASKS.md) ====="; printf '%s\n' "$card"; echo
  for f in $files; do
    path="$f"
    [ -e "$path" ] || [ ! -e "HiAgain/$f" ] || path="HiAgain/$f"
    [ -e "$path" ] || { found=$(find HiAgain -name "$(basename "$f")" -o -name "$(basename "$f").swift" | head -1); [ -n "$found" ] && path="$found"; }
    if [ -f "$path" ]; then echo "===== $path ====="; cat "$path"; echo
    else echo "===== $f (does not exist yet) ====="; echo; fi
  done
} > /tmp/hiagain-pack.txt

pbcopy < /tmp/hiagain-pack.txt
echo "Copied $(wc -c < /tmp/hiagain-pack.txt | tr -d ' ') characters for card $id."
