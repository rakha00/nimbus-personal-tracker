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

Some decisions:

- **No backend code.** PocketBase gives auth, a REST API and per-record access rules
  (`owner = @request.auth.id`), so the app talks to it directly. Public sign-up is off.
- **Balances are computed, not stored.** `ledger.dart` derives every balance and every
  person's outstanding loan from the transactions, so nothing can drift out of sync. It is plain
  Dart with unit tests.
- **One feature, one module.** Each feature has its own collection(s) and its own folder under
  `app/lib/features/`, so new trackers can be added without touching the others.
- **Schema as code.** Every schema change is a migration file in `server/pb_migrations/`.

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

## License

MIT, see [LICENSE](LICENSE).
