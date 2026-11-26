# Nimbus

A personal Android app for tracking my money and keeping a daily diary, backed by a small
self-hosted server. Built for one user (me), in Indonesian with an English option.

It replaced a Google Sheet for finances and a notes page for the diary, and it is the first step
toward a personal tracking app that an AI assistant can later read through MCP.

## Features

- **Finance**: accounts (cash, bank, e-wallet) with balances computed from an opening balance and
  every transaction; income, expenses, transfers between accounts, and loans to or from people
  (lend, paid back, borrow, pay back) with the outstanding amount per person.
- **Filters**: month navigation plus type, account, category and text search. The in/out summary
  and the spending-by-category list follow the filter.
- **Diary**: one entry per day, today's entry always on top.
- **Media log**: a wishlist of films and books, and a log of what's been watched or read, with
  date finished, a 1–5 rating and notes. Search fills in cover, year, director or author and
  synopsis from TMDB (films, needs `TMDB_KEY` in `config.json`) or Google Books.
- **Assistant** (✦ in the app bar): *record* turns a sentence like "lunch 25k cash" into drafts
  that open in the normal forms to check and save; *ask* answers questions about the data. It
  runs Claude Code on the server with read-only access (see AI worker below).
- **Device lock**: the app opens with the phone's own fingerprint or PIN and locks again after a
  minute in the background. There is no in-app login screen after the one-time setup.
- **Light and dark theme**, Indonesian and English UI.

## Architecture

```
Flutter app (Android)  ──HTTPS──▶  PocketBase (Docker, behind Traefik on a VPS)
  local_auth, secure storage          SQLite, REST API, admin panel
```

| Part | Stack |
| --- | --- |
| `app/` | Flutter 3, Material 3, `pocketbase`, `local_auth`, `flutter_secure_storage`, `intl` / gen-l10n |
| `server/` | PocketBase in Docker Compose, routed by Traefik with Let's Encrypt; schema as JS migrations |
| `mcp/` | Read-only MCP server (Dart, stdio) so an AI assistant can read the data, and the AI worker |

Some decisions:

- **No backend code.** PocketBase gives auth, a REST API and per-record access rules
  (`owner = @request.auth.id`), so the app talks to it directly. Public sign-up is off.
- **Balances are computed, not stored.** `ledger.dart` derives every balance and every
  person's outstanding loan from the transactions, so nothing can drift out of sync. It is plain
  Dart with unit tests.
- **One feature, one module.** Each feature has its own collection(s) and its own folder under
  `app/lib/features/`, so new trackers can be added without touching the others.
- **Schema as code.** Every schema change is a migration file in `server/pb_migrations/`.
- **AI reads, never writes.** The MCP server logs in as an `ai_readers` account. PocketBase rules
  let it read its owner's records, and every write rule requires a `users` login, so the database
  itself refuses writes from the AI. It reuses `ledger.dart`, so its balances match the app's.

## Running it

### Server

```sh
cd server
cp .env.example .env          # set NIMBUS_HOST to your domain
docker compose up -d --build  # expects an external Traefik network named dokploy-network
```

Open `https://<NIMBUS_HOST>/_/` to create the admin account, then add one user in the `users`
collection for the app.

Backups (`server/backup/`): a systemd timer runs `nimbus-backup` nightly. It copies the database
with SQLite's online backup API, checks its integrity, keeps 14 days on the server, and, when an
rclone remote named `gdrive` exists, uploads to Google Drive and keeps 60 days there.

```sh
install -m 755 server/backup/nimbus-backup.sh /usr/local/bin/nimbus-backup
cp server/backup/nimbus-backup.{service,timer} /etc/systemd/system/
systemctl daemon-reload && systemctl enable --now nimbus-backup.timer
rclone config create gdrive drive scope=drive.file && rclone config reconnect gdrive:
```

### App

```sh
cd app
cp config.example.json config.json   # set NIMBUS_SERVER to https://<NIMBUS_HOST>
flutter test
flutter build apk --release --dart-define-from-file=config.json
```

The APK is in `app/build/app/outputs/flutter-apk/`. On first launch it asks once for the user's
email and password, then uses the phone's lock from then on.

### MCP server

Tools: `lookup`, `finance_status`, `finance_summary`, `transactions`, `diary`, `media`, `events`,
each limited to a date range or 100 rows. It reads `NIMBUS_SERVER`, `AI_EMAIL` and `AI_PASSWORD`
(an `ai_readers` record made in the admin panel) from the environment or from the file named by
`NIMBUS_ENV_FILE`.

```sh
cd mcp
dart test
scp ../server/ai/nimbus-mcp root@<server>:/usr/local/bin/   # built as in "AI worker" below
# Claude Code on a laptop, over SSH, so the password stays on the server:
claude mcp add nimbus -- ssh root@<server> NIMBUS_ENV_FILE=/opt/nimbus/ai.env nimbus-mcp
```

### AI worker

The app adds a row to `ai_requests` (mode `record` or `ask`, plus a short prompt). The worker
(`mcp/bin/worker.dart`, container `ai` in `server/compose.yml`) picks it up, runs Claude Code
headless with the owner's Claude subscription, and writes back an answer and, for `record`,
drafts: suggested records only the user can save. The AI itself can't write.

Claude Code runs with no built-in tools (no shell, files or web), only the Nimbus MCP server, a
short system prompt, JSON output against a fixed schema, no saved sessions, a 90 s timeout and
30 requests an hour. The container is read-only, non-root, drops all capabilities, has 512 MB
and 1 CPU, and stays off the shared Traefik network.

```sh
cd mcp
dart compile exe bin/worker.dart --target-os=linux --target-arch=x64 -o ../server/ai/nimbus-worker
dart compile exe bin/nimbus_mcp.dart --target-os=linux --target-arch=x64 -o ../server/ai/nimbus-mcp
# server/ai.env: NIMBUS_SERVER, AI_EMAIL, AI_PASSWORD, CLAUDE_CODE_OAUTH_TOKEN (`claude setup-token`)
cd ../server && docker compose up -d --build ai   # stop with: docker compose stop ai
```

## License

MIT, see [LICENSE](LICENSE).
