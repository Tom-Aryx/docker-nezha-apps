#!/usr/bin/env sh

if [[ $1 ]]; then

    if [ ! -e /app/nezha/backup ]; then
        mkdir -p /app/nezha/backup
    fi

    if [ ! -e /app/nezha/backup/backup.sql ]; then
        rm /app/nezha/backup/* /app/nezha/backup/.*
        git clone $1 /app/nezha/backup
    else
        cd /app/nezha/backup && git pull
    fi

    if [ -s /app/nezha/backup/backup.sql ]; then
        sqlite3 /app/nezha/backup/restore.db  ".read /app/nezha/backup/backup.sql"

        supervisorctl stop nezha
        mv /app/nezha/backup/restore.db /dashboard/data/sqlite.db
        supervisorctl start nezha
    fi
fi