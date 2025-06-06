#!/usr/bin/env sh

if [[ $1 ]]; then

    if [ ! -e /app/nezha/backup ]; then
        mkdir -p /app/nezha/backup
    fi

    if [ ! -e /app/nezha/backup/backup.sql ]; then
        rm /app/nezha/backup/* /app/nezha/backup/.*
        git clone $1 /app/nezha/backup
    fi

    sqlite3 /app/nezha/data/sqlite.db ".dump" > /app/nezha/backup/backup.sql

    cd /app/nezha/backup
    git config user.name ${GITHUB_NAME}
    git config user.email ${GITHUB_EMAIL}

    git add .
    git commit -m "Backup sqlite.db"
    git push
fi