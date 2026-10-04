#!/usr/bin/env bash
# verify_db_restore.sh — confirm a live Postgres DB was restored from a given
# pg_dump (custom-format .dump) file. Read-only on the live DB; no superuser and
# no CREATEDB rights required (uses a TEMP table inside the live connection).
#
# Usage:
#   verify_db_restore.sh DUMP_FILE [TABLE] [ORDER_COL]
#
#   DUMP_FILE   path to a `pg_dump -Fc` archive (a prod backup .dump)
#   TABLE       table to compare (default: mail_message)
#   ORDER_COL   deterministic ordering column for the hash (default: id)
#
# Connection: standard PG* env vars (PGHOST/PGPORT/PGUSER/PGDATABASE/PGPASSWORD)
# or ~/.pgpass, exactly like `psql` with no args.
#
# Exit: 0 = MATCH, 1 = MISMATCH, 2/3 = usage / dump problem.
#
# See ../references/db_restore_verification.md for the reasoning behind each step.

set -euo pipefail

DUMP=${1:-}
TABLE=${2:-mail_message}
ORDER_COL=${3:-id}

if [ -z "$DUMP" ]; then
  echo "usage: verify_db_restore.sh DUMP_FILE [TABLE] [ORDER_COL]" >&2
  exit 2
fi
if [ ! -r "$DUMP" ]; then
  echo "ERROR: cannot read dump file: $DUMP" >&2
  exit 2
fi

hr() { printf '=== %s ===\n' "$1"; }

hr "dump archive header"
pg_restore -l "$DUMP" | grep -E '^;' | head -n 12 || true
echo

hr "target database"
psql -tAc "SELECT current_database() || ' @ ' || coalesce(host(inet_server_addr()),'local') || ':' || inet_server_port();" || true
psql -tAc "SELECT 'server_now = ' || now();" || true
echo

hr "live data horizon (newest rows on this instance)"
psql <<'SQL' || true
SELECT 'mail_message'  AS tbl, max(create_date) AS newest FROM mail_message
UNION ALL SELECT 'ir_attachment', max(create_date) FROM ir_attachment
UNION ALL SELECT 'ir_logging',    max(create_date) FROM ir_logging
ORDER BY tbl;
SQL
echo

# --- extract the dump's data for TABLE in a single pass ---
raw=$(mktemp -t verify_db_restore.raw.XXXXXX)
dat=$(mktemp -t "verify_db_restore.${TABLE}.XXXXXX")
trap 'rm -f "$raw" "$dat"' EXIT

pg_restore -a -t "$TABLE" -f - "$DUMP" 2>/dev/null > "$raw" || true

COLS=$(grep -m1 '^COPY ' "$raw" | sed -E 's/^COPY [^(]*\(([^)]*)\).*/\1/' || true)
if [ -z "$COLS" ]; then
  echo "ERROR: table '$TABLE' has no data section in this dump" >&2
  exit 3
fi

awk '/^COPY .* FROM stdin;$/{c=1;next} /^\\\.$/{c=0} c' "$raw" > "$dat"

dump_rows=$(wc -l < "$dat" | tr -d ' ')
live_rows=$(psql -tAc "SELECT count(*) FROM $TABLE;")

hr "row count ($TABLE)"
printf 'dump: %s\nlive: %s\n' "$dump_rows" "$live_rows"
echo

hr "content hash ($TABLE, per-row md5 aggregated in $ORDER_COL order)"
read -r live_md5 dump_md5 < <(
  psql -tAF' ' -v ON_ERROR_STOP=1 <<SQL
CREATE TEMP TABLE _verify_dump (LIKE $TABLE);
\copy _verify_dump ($COLS) FROM '$dat'
SELECT
  (SELECT md5(string_agg(md5(a::text), '' ORDER BY a.$ORDER_COL)) FROM $TABLE       a),
  (SELECT md5(string_agg(md5(b::text), '' ORDER BY b.$ORDER_COL)) FROM _verify_dump b);
SQL
)
printf 'live_md5: %s\ndump_md5: %s\n' "$live_md5" "$dump_md5"
echo

if [ -n "$live_md5" ] && [ "$live_md5" = "$dump_md5" ] && [ "$dump_rows" = "$live_rows" ]; then
  echo "VERDICT: MATCH — live DB '${PGDATABASE:-?}' is the restore of $(basename "$DUMP") (table $TABLE verified row-for-row)"
  exit 0
fi

echo "VERDICT: MISMATCH — live DB is NOT (only) this dump. Check the data horizon above and ~/.bash_history for the real pg_restore source."
exit 1
