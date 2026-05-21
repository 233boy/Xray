install_service() {
    # alpine: 使用 OpenRC
    if [[ $is_alpine ]]; then
        case $1 in
        xray | v2ray)
            cat >/etc/init.d/$is_core <<EOF
#!/sbin/openrc-run
name="$is_core_name"
description="$is_core_name Service"
command="$is_core_bin"
command_args="run -config $is_config_json -confdir $is_conf_dir"
command_background=true
pidfile="/run/\${RC_SVCNAME}.pid"
output_log="$is_log_dir/openrc.log"
error_log="$is_log_dir/openrc.err"
rc_ulimit="-n 1048576"

depend() {
    need net
    use dns
    after network
}
EOF
            chmod +x /etc/init.d/$is_core
            ;;
        caddy)
            cat >/etc/init.d/caddy <<EOF
#!/sbin/openrc-run
name="Caddy"
description="Caddy"
command="$is_caddy_bin"
command_args="run --environ --config $is_caddyfile --adapter caddyfile"
command_background=true
pidfile="/run/\${RC_SVCNAME}.pid"
rc_ulimit="-n 1048576"

depend() {
    need net
    use dns
    after network
}
EOF
            chmod +x /etc/init.d/caddy
            ;;
        esac
        rc-update add $1 default &>/dev/null
        return
    fi

    case $1 in
    xray | v2ray)
        is_doc_site=https://xtls.github.io/
        [[ $1 == 'v2ray' ]] && is_doc_site=https://www.v2fly.org/
        cat >/lib/systemd/system/$is_core.service <<<"
[Unit]
Description=$is_core_name Service
Documentation=$is_doc_site
After=network.target nss-lookup.target

[Service]
#User=nobody
User=root
NoNewPrivileges=true
ExecStart=$is_core_bin run -config $is_config_json -confdir $is_conf_dir
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1048576
PrivateTmp=true
ProtectSystem=full
#CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
#AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target"
        ;;
    caddy)
        cat >/lib/systemd/system/caddy.service <<<"
#https://github.com/caddyserver/dist/blob/master/init/caddy.service
[Unit]
Description=Caddy
Documentation=https://caddyserver.com/docs/
After=network.target network-online.target
Requires=network-online.target

[Service]
Type=notify
User=root
Group=root
ExecStart=$is_caddy_bin run --environ --config $is_caddyfile --adapter caddyfile
ExecReload=$is_caddy_bin reload --config $is_caddyfile --adapter caddyfile
TimeoutStopSec=5s
LimitNPROC=10000
LimitNOFILE=1048576
PrivateTmp=true
ProtectSystem=full
#AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target"
        ;;
    esac

    # enable, reload
    systemctl enable $1
    systemctl daemon-reload
}
