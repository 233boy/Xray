is_ip_strategy_list=(
    AsIs
    UseIPv4v6
    UseIPv6v4
)
ip_set() {
    is_tmp_list=(自动 优先IPv4 优先IPv6)
    ask list is_ip_use null "\n请选择出站 IP 优先级:\n"
    is_ip_strategy=${is_ip_strategy_list[$REPLY - 1]}
    if [[ $is_ip_strategy == 'AsIs' ]]; then
        cat <<<$(jq '(.outbounds[] | select(.tag == "direct" and .protocol == "freedom")) |= (del(.settings.domainStrategy) | if .settings == {} then del(.settings) else . end)' $is_config_json) >$is_config_json
    else
        cat <<<$(jq --arg strategy "$is_ip_strategy" '(.outbounds[] | select(.tag == "direct" and .protocol == "freedom") | .settings.domainStrategy) = $strategy' $is_config_json) >$is_config_json
    fi
    manage restart &
    msg "\n已更新出站 IP 优先级为: $(_green $is_ip_use)\n"
}
