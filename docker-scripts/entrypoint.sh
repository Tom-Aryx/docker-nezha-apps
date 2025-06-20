#!/usr/bin/env sh

DIR_APP="/app"
DIR_NEZHA="/app/nezha"
DIR_AGENT="/app/nezha-agent"
DIR_ADGUARD="/app/AdGuard"
DIR_CADDY="/app/caddy"
DIR_NTFY="/app/ntfy"

DIR_CONFIG="/app/config"
DIR_SCRIPTS="/app/scripts"

JWT_SECRET=${JWT_SECRET:-"$(openssl rand -base64 48 | sed 's/[\+\/]/q/g')"}
AGENT_SECRET=${AGENT_SECRET:-"$(openssl rand -base64 24 | sed 's/[\+\/]/q/g')"}
AGENT_UUID=${AGENT_UUID:-"$(uuidgen)"}
# NEZHA_DOMAIN
# ADGUARD_USER
# ADGUARD_PWD
# NTFY_BASEURL
# NTFY_WEBPUSH_EMAIL
# NTFY_WEBPUSH_PUBKEY
# NTFY_WEBPUSH_PRIKEY
# GITHUB_REPO
# AUTO_RESTORE

# first run
if [ ! -s /etc/supervisor.d/apps.ini ]; then
    ## ========== permission ==========
    chmod +x ${DIR_NEZHA}/dashboard-linux-amd64 \
        ${DIR_AGENT}/nezha-agent \
        ${DIR_ADGUARD}/AdGuard \
        ${DIR_CADDY}/caddy \
        ${DIR_NTFY}/ntfy \
        ${DIR_SCRIPTS}/*.sh
    ## ========== nezha ==========
    if [ ! -e ${DIR_NEZHA}/data/config.yaml ]; then
        # copy
        cp ${DIR_CONFIG}/nezha/config.yaml ${DIR_NEZHA}/data/config.yaml
        # replace
        sed -e "s#-jwt-secret-key-#$JWT_SECRET#" \
            -e "s#-agent-secret-key-#$AGENT_SECRET#" \
            -e "s#-install-host-#$NEZHA_DOMAIN:443#" \
            -i ${DIR_NEZHA}/data/config.yaml
    fi
    NEZHA_CMD="${DIR_NEZHA}/dashboard-linux-amd64 -c ${DIR_NEZHA}/data/config.yaml -db ${DIR_NEZHA}/data/sqlite.db"
    ## ========== nezha-agent ==========
    if [ ! -e ${DIR_AGENT}/config.yaml ]; then
        # copy
        cp ${DIR_CONFIG}/nezha-agent/config.yaml ${DIR_AGENT}/config.yaml
        # replace
        sed -e "s#-uuid-#$AGENT_UUID#" \
            -e "s#-agent-secret-key-#$AGENT_SECRET#" \
            -i ${DIR_AGENT}/config.yaml
    fi
    AGENT_CMD="${DIR_AGENT}/nezha-agent -c ${DIR_AGENT}/config.yaml"
    ## ========== AdGuardHome ==========
    if [ ! -e ${DIR_ADGUARD}/AdGuardHome.yaml ]; then
        # copy
        cp ${DIR_CONFIG}/AdGuard/AdGuardHome.yaml ${DIR_ADGUARD}/AdGuardHome.yaml
        # replace
        sed -e "s#-user-#$ADGUARD_USER#" \
            -e "s#-password-#$ADGUARD_PWD#" \
            -i ${DIR_ADGUARD}/AdGuardHome.yaml
    fi
    # cert
    mkdir -p ${DIR_ADGUARD}/cert
    openssl ecparam -out ${DIR_ADGUARD}/cert/adguard.key -name prime256v1 -genkey
    openssl req -new -subj "/CN=dns.adguard.com" -key ${DIR_ADGUARD}/cert/adguard.key -out ${DIR_ADGUARD}/cert/adguard.csr
    openssl x509 -req -days 36500 -in ${DIR_ADGUARD}/cert/adguard.csr -signkey ${DIR_ADGUARD}/cert/adguard.key -out ${DIR_ADGUARD}/cert/adguard.pem
    # command
    ADGUARD_CMD="${DIR_ADGUARD}/AdGuard --no-check-update -c ${DIR_ADGUARD}/AdGuardHome.yaml -w ${DIR_ADGUARD}"
    ## ========== Caddy ==========
    if [ ! -e ${DIR_CADDY}/Caddyfile ]; then
        # copy
        cp ${DIR_CONFIG}/caddy/Caddyfile ${DIR_CADDY}/Caddyfile
    fi
    CADDY_CMD="${DIR_CADDY}/caddy run --config ${DIR_CADDY}/Caddyfile --watch"
    ## ========== ntfy ==========
    if [ ! -e ${DIR_NTFY}/config.yaml ]; then
        # copy
        cp ${DIR_CONFIG}/ntfy/config.yaml ${DIR_NTFY}/config.yaml
        # replace
        sed -e "s#-base-url-#$NTFY_BASEURL#" \
            -e "s#-email-addr-#$NTFY_WEBPUSH_EMAIL#" \
            -e "s#-public-key-#$NTFY_WEBPUSH_PUBKEY#" \
            -e "s#-private-key-#$NTFY_WEBPUSH_PRIKEY#" \
            -i ${DIR_NTFY}/config.yaml
    fi
    # files
    mkdir -p /app/ntfy/attachments
    touch /app/ntfy/data/cache.db /app/ntfy/data/user.db /app/ntfy/data/webpush.db /app/ntfy/ntfy.log
    # add admin
    ${DIR_NTFY}/ntfy user -c ${DIR_NTFY}/config.yaml add -r admin ${NTFY_USER:-'admin'}
    # revoke topic
    ${DIR_NTFY}/ntfy access -c ${DIR_NTFY}/config.yaml everyone 'serv*' deny
    # command
    NTFY_CMD="${DIR_NTFY}/ntfy serve -c ${DIR_NTFY}/config.yaml"
    ## ========== supervisor ==========
    # copy
    mkdir -p /etc/supervisor.d
    cp ${DIR_CONFIG}/apps.ini /etc/supervisor.d/apps.ini
    # replace
    sed -e "s#-nezha-cmd-#$NEZHA_CMD#g" \
        -e "s#-agent-cmd-#$AGENT_CMD#g" \
        -e "s#-adguard-cmd-#$ADGUARD_CMD#g" \
        -e "s#-caddy-cmd-#$CADDY_CMD#g" \
        -e "s#-ntfy-cmd-#$NTFY_CMD#g" \
        -i /etc/supervisor.d/apps.ini
fi

if [ ! -z "$AUTO_RESTORE" ]; then
    ${DIR_SCRIPTS}/restore.sh "$GITHUB_REPO"
fi

# RUN freshrss
/var/www/FreshRSS/Docker/entrypoint.sh && ([ -z "$CRON_MIN" ] || crond -d 6) && httpd -D BACKGROUND
# RUN supervisor
supervisord -c /etc/supervisord.conf
