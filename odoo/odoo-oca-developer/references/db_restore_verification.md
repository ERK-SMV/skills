# Verifying a Postgres DB was restored from a given dump ("odoo_restauration_check")

Use this when someone loaded a `pg_dump` file (typically a prod backup) into an Odoo
database and you need to **prove the running instance is actually serving that dump** —
not an older restore, not live prod, not an empty bootstrap DB. Common after a
`docky run` / container start where success only means "a DB was reachable", not
"the DB I intended".

Everything here is **read‑only** on the live DB and works **without superuser** and
**without `CREATEDB`** rights (an app role is usually pinned by `pg_hba.conf` to its
own database — you cannot spin up a scratch DB to restore into).

Helper script: [`scripts/verify_db_restore.sh`](../scripts/verify_db_restore.sh)
runs the whole sequence and prints `VERDICT: MATCH` / `MISMATCH`.

---

## The evidence stack (weakest → strongest)

Run them in order and stop when you are convinced. Any single one can mislead; the
combination is conclusive.

### 1. Which DB is the container actually using

The web container starting is not evidence. Confirm the DB name Odoo connects to,
then check *that* DB:

```bash
grep -E '^\s*db_(name|host|user)' /odoo/etc/odoo.cfg
env | grep -iE 'pg(host|database|user|port)|db_'   # docky/akretion images export PG* directly
```

`PGDATABASE` / `db_name` is what every check below must target.

### 2. Dump file header — what the dump claims to be

```bash
pg_restore -l backup_prod_YYYYMMDD_HHMM.dump | grep -E '^;' | head
```

Gives:

```
; Archive created at 2026-08-28 16:00:04 UTC
;     dbname: prod
```

`Archive created at` is the source snapshot time. Note it — the live data horizon
(step 3) must line up with it. Also sanity‑check the filename's date against
`ls -alth` mtime; they often disagree (label vs. actual creation).

### 3. Live data horizon — does the newest row match the snapshot time

A restored snapshot has **nothing newer than the dump's creation time** (bar your
own logins / cron since the restore). Live prod, or an older restore, will not
match.

```sql
SELECT 'mail_message'  AS t, max(create_date) FROM mail_message
UNION ALL SELECT 'ir_attachment', max(create_date) FROM ir_attachment
UNION ALL SELECT 'ir_logging',    max(create_date) FROM ir_logging;
```

Pick tables that actually grow continuously on this deployment. On a
validator/portal‑type Odoo, `account_move` / `sale_order` may be permanently
empty — that's normal, don't treat an empty table as a failure, just choose a
different one (`mail_message` and `ir_attachment` are reliable).

Read it as:
- newest rows cluster just **before** the dump's `Archive created at`, nothing after → it's this snapshot ✅
- rows dated **today** with real activity → not this restore (still live prod, or an older restore that's been used since) ❌
- horizon weeks earlier than expected → an **older** dump is loaded (classic: bash history shows a `pg_restore` of a stale `*.dump`)

Check `~/.bash_history` for `pg_restore|createdb|dropdb|load_db|get_db` — the last
restore command there often names a *different* file than the one you think is
live.

### 4. Row count of one table: dump vs. live

```bash
# rows inside the dump's COPY stream for one table
pg_restore -a -t mail_message -f - backup_prod_*.dump 2>/dev/null \
  | awk '/^COPY .* FROM stdin;$/{c=1;next} /^\\\.$/{c=0} c' | wc -l

# rows live
psql -tAc "SELECT count(*) FROM mail_message;"
```

`pg_restore -a` (data‑only) still emits a small SQL preamble/postamble (`SET`
lines, `--` comment blocks, the `COPY … FROM stdin;` line, the terminating `\.`).
The `awk` above already strips it to pure data rows. If you count the raw stream
instead (`grep -c '^'`), expect the live count to be ~20–35 **lower** — that gap
is exactly the preamble, not missing data. In `COPY` text format embedded
newlines are escaped (`\n`), so one row = one physical line; multi‑line HTML
bodies do not inflate the count.

Equal counts are strong but not proof (equal inserts + deletes could hide it) —
hence step 5.

### 5. Content hash: dump vs. live, without a scratch DB

Load the dump's table data into a **TEMP table inside the live connection** and
hash both sides. TEMP tables need no special rights and vanish with the session.

```bash
DUMP=~/backup_prod_20260828_1700.dump
TABLE=mail_message

# one pass over the dump: capture data-only output
raw=$(mktemp); dat=$(mktemp)
pg_restore -a -t "$TABLE" -f - "$DUMP" 2>/dev/null > "$raw"

# exact column list the dump uses (order matters for \copy)
COLS=$(grep -m1 '^COPY ' "$raw" | sed -E 's/^COPY [^(]*\(([^)]*)\).*/\1/')

# pure data rows
awk '/^COPY .* FROM stdin;$/{c=1;next} /^\\\.$/{c=0} c' "$raw" > "$dat"

psql -v ON_ERROR_STOP=1 <<SQL
CREATE TEMP TABLE _verify_dump (LIKE $TABLE);
\copy _verify_dump ($COLS) FROM '$dat'
SELECT
  (SELECT md5(string_agg(md5(a::text), '' ORDER BY a.id)) FROM $TABLE       a) AS live_md5,
  (SELECT md5(string_agg(md5(b::text), '' ORDER BY b.id)) FROM _verify_dump b) AS dump_md5;
SQL
rm -f "$raw" "$dat"
```

Identical `live_md5` / `dump_md5` → the live table **is** the dump's table,
row‑for‑row, every column. A mismatch anywhere changes the hash.

Notes:
- Per‑row `md5(a::text)` first, *then* aggregate — keeps the aggregated string at
  32 bytes/row instead of buffering the whole table's text in memory.
- `\copy … ($COLS)` with the dump's own column list survives schema drift between
  the dump and the live table (extra/reordered columns).
- `COPY` uses `\N` for NULL by default and `\copy` expects the same — no extra
  handling needed.
- A lighter variant hashes only stable columns:
  `md5(string_agg(id::text||'|'||coalesce(write_date::text,''), ',' ORDER BY id))`
  — good enough for a fast check, but the full‑row hash is the definitive one.

---

## Things that look useful but are not

| Signal | Why it doesn't tell you the restore time |
|---|---|
| `ir_config_parameter` `database.uuid` / `database.create_date` | Copied verbatim from the source on every restore — confirms "this is *that* prod's data", says nothing about *when* you loaded it. |
| `web.base.url` | Same — a prod value just means prod data, not a fresh load. |
| `pg_stat_database.stats_reset` | Often `NULL` and only meaningful to a superuser / after an explicit reset; inconclusive on a locked‑down app role. |
| `pg_stat_file('base/<oid>/PG_VERSION')` mtime (DB creation time) | The *right* idea, but `pg_stat_file` needs superuser / `pg_read_server_files` — usually denied for the app role (`droit refusé pour la fonction pg_stat_file`). Only works if you can reach the PG host filesystem or connect as a superuser. |
| `docky run` / container started OK | Only means a DB was reachable — it will happily serve a stale or empty DB. |

---

## `pg_hba.conf` wall

`createdb fnfempe_verify` can *succeed* (it connects via `template1`/`postgres`)
yet `psql -d fnfempe_verify` / `pg_restore -d fnfempe_verify` then fails with
`aucune entrée dans pg_hba.conf pour … base de données "fnfempe_verify"` — the app
role is allowed into its own DB only. That is why step 5 uses a TEMP table in the
existing connection instead of a second database. If you *do* have superuser or a
permissive `pg_hba`, the classic approach also works: `createdb verify` →
`pg_restore -d verify --no-owner DUMP` → hash the same way → `dropdb verify`.
