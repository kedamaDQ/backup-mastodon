# backup-mastodon
Periodical backup scripts for mastodon servers.

## dependencies

- pg_dump / pg_restore
- redis-cli

## setup

### clone this repository

```
$ git clone https://github.com/kedamaDQ/backup-mastodon.git
```

### copy sample .env files and edit according to your environment

```
$ cd backup-mastodon
$ cp .env.backup-mastodon.sample .env.backup-mastodon
$ cp backup-mastodon.d/.env.backup-postgresql.sample backup-mastodon.d/.env.backup-postgresql
$ cp backup-mastodon.d/.env.backup-redis.sample backup-mastodon.d/.env.backup-redis
```

.env files are:

- /.env.backup-mastodon
- /backup-mastodon.d/.env.backup-postgresql
- /backup-mastodon.d/.env.backup-redis

### test run

run as root.

```
# ./backup-mastodon.sh
```

if succeeded, 3 files are created in directory which is defined by environment variable `${BACKUP_DEST_DIR}` in /.env.backup-mastodon.

## periodical backing up

create drop-in file in /etc/cron.d.

```
03 04 * * * root /bin/bash /path/to/backup-mastodon/backup-mastodon.sh > /tmp/backup-mastodon.out 2>&1
```

or edit root's crontab.

```
03 04 * * * /bin/bash /path/to/backup-mastodon/backup-mastodon.sh > /tmp/backup-mastodon.out 2>&1
```
