# CLIProxyAPI billing bot on whale

The Quadlet unit runs `ghcr.io/averyanalex/cliproxy-billing-bot:main` on the
existing `cliproxyapi` network. It reaches Usage Keeper by its internal container
name and stores the SQLite ledger at `/persist/cliproxy-billing-bot/data/billing.db`.
The image runs as UID/GID 10001, mapped to host UID/GID 110001. The service has
no inbound port and must run as a single replica because it uses Telegram long
polling and SQLite.

`env.age` is an encrypted agenix template containing the keys shown in
`env.example`. Before activating the service, edit it from the dotfiles root:

```sh
agenix -e apps/cliproxy-billing-bot/env.age
```

Set the real Telegram bot token, numeric admin Telegram ID(s) separated by
commas, and the Usage Keeper login password. The Keeper URL, database path and
time zone are set in `default.nix`. The placeholder values are not usable.
The recipient entry in the root `secrets.nix` symlink lives in the `secrets`
Git submodule; include that submodule change when later committing this setup.

The `cliproxy-billing-bot` Rustic job runs on whale's normal daily schedule. It
backs up the ledger with an online SQLite copy in backup staging and excludes
the live database and its WAL/SHM files. On restore, stop the bot, restore
`billing.db` to the persistent data directory with ownership `110001:110001`,
remove any stale `billing.db-wal` and `billing.db-shm`, then start the bot.
