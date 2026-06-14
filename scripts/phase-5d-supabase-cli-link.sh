#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Corra Booth - Phase 5D Supabase CLI Link"
echo "========================================"

PROJECT_REF="uitnzrstkjvwiojbnpwg"

fail() {
  echo ""
  echo "ERROR: $1"
  echo ""
  exit 1
}

echo ""
echo "Checking repository structure..."

[ -f "package.json" ] || fail "Root package.json not found. Run from repo root."
[ -d "infra/supabase/migrations" ] || fail "infra/supabase/migrations not found."

SQL_COUNT="$(find infra/supabase/migrations -maxdepth 1 -type f -name "*.sql" | wc -l | tr -d ' ')"

echo "Infra SQL migration count: $SQL_COUNT"

if [ "$SQL_COUNT" -lt 18 ]; then
  fail "Expected 18 SQL migration files. Run Phase 5A, 5B, and 5C first."
fi

echo "Repository structure OK."

echo ""
echo "Installing Supabase CLI package if needed..."

if ! pnpm exec supabase --version >/dev/null 2>&1; then
  pnpm add -D -w supabase
fi

echo "Supabase CLI version:"
pnpm exec supabase --version

echo ""
echo "Creating standard Supabase CLI folder..."

mkdir -p supabase/migrations

if [ ! -f "supabase/config.toml" ]; then
  echo "Initializing Supabase CLI config..."
  pnpm exec supabase init
else
  echo "Supabase CLI config already exists."
fi

echo ""
echo "Syncing migrations from infra/supabase/migrations to supabase/migrations..."

rm -f supabase/migrations/*.sql
cp infra/supabase/migrations/*.sql supabase/migrations/

echo ""
echo "Checking synced migrations..."

SYNCED_SQL_COUNT="$(find supabase/migrations -maxdepth 1 -type f -name "*.sql" | wc -l | tr -d ' ')"

echo "Synced SQL migration count: $SYNCED_SQL_COUNT"

if [ "$SYNCED_SQL_COUNT" -lt 18 ]; then
  fail "Migration sync failed. Expected 18 SQL files in supabase/migrations."
fi

ls -1 supabase/migrations/*.sql | sort

echo ""
echo "========================================"
echo " Phase 5D preparation completed."
echo "========================================"
echo ""
echo "Next commands:"
echo "  pnpm exec supabase login"
echo "  pnpm exec supabase link --project-ref $PROJECT_REF"
echo "  pnpm exec supabase db push"
echo ""
