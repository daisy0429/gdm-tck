#!/usr/bin/env bash
# 健康检查模块
# 负责验证 GDM 服务的可用性（HTTP 健康端点 + Bolt 连通性）

# 检查单个 metrics/健康端点
# 参数: $1 - metrics地址 (host:port)
check_health_endpoint() {
    local addr="$1"
    local url="http://${addr}/ready"

    local response
    response=$(ssh_exec "curl -s -o /dev/null -w '%{http_code}' '${url}' 2>/dev/null || echo '000'")

    if [ "$response" = "200" ]; then
        return 0
    fi
    return 1
}

# 检查 Bolt 端口连通性
# 参数: $1 - 主机, $2 - 端口
check_bolt_port() {
    local host="$1"
    local port="$2"

    ssh_exec "timeout 3 bash -c '</dev/tcp/${host}/${port}' 2>/dev/null"
}

# 等待单个节点健康
# 参数: $1 - 节点名称, $2 - metrics地址, $3 - bolt端口
wait_for_node_health() {
    local node_name="$1"
    local metrics_addr="$2"
    local bolt_port="$3"

    log_info "等待 ${node_name} 就绪 (超时: ${HEALTH_CHECK_TIMEOUT}s)..."

    local elapsed=0
    while [ $elapsed -lt "$HEALTH_CHECK_TIMEOUT" ]; do
        # 检查健康端点
        if check_health_endpoint "$metrics_addr"; then
            # 再检查 Bolt 端口
            if check_bolt_port "$REMOTE_HOST" "$bolt_port"; then
                log_info "${node_name} 就绪 (耗时: ${elapsed}s)"
                return 0
            fi
        fi

        sleep "$HEALTH_CHECK_INTERVAL"
        elapsed=$((elapsed + HEALTH_CHECK_INTERVAL))
    done

    log_error "${node_name} 在 ${HEALTH_CHECK_TIMEOUT}s 内未就绪"
    return 1
}

# 验证单机版环境可用性
verify_standalone() {
    log_step "验证单机版环境可用性"
    wait_for_node_health "standalone" "$STANDALONE_METRICS_ADDR" "$STANDALONE_BOLT_PORT"
}

# 验证集群版环境可用性
verify_cluster() {
    log_step "验证集群版环境可用性"

    local all_healthy=true
    for i in "${!TMUX_CLUSTER_SESSIONS[@]}"; do
        local node="${TMUX_CLUSTER_SESSIONS[$i]}"
        local metrics_addr="${CLUSTER_METRICS_ADDRS[$i]}"
        local bolt_port="${CLUSTER_BOLT_PORTS[$i]}"

        if ! wait_for_node_health "$node" "$metrics_addr" "$bolt_port"; then
            all_healthy=false
        fi
    done

    if [ "$all_healthy" = true ]; then
        log_info "集群所有节点就绪"
        return 0
    else
        log_error "集群部分节点未就绪"
        return 1
    fi
}

# 执行 Bolt 查询验证（使用 cypher-shell 或简单端口测试）
verify_bolt_query() {
    local host="$1"
    local port="$2"
    local node_name="$3"

    log_info "验证 ${node_name} Bolt 查询连通性 (${host}:${port})"

    if check_bolt_port "$host" "$port"; then
        log_info "${node_name} Bolt 端口可达"
        return 0
    else
        log_error "${node_name} Bolt 端口不可达"
        return 1
    fi
}

# 打印环境可用性摘要
print_health_summary() {
    local mode="$1"

    log_separator
    log_info "环境可用性检查摘要"
    log_separator

    if [[ "$mode" == "standalone" || "$mode" == "all" ]]; then
        echo "  单机版:"
        echo "    Bolt 端口: ${REMOTE_HOST}:${STANDALONE_BOLT_PORT}"
        echo "    Metrics: http://${STANDALONE_METRICS_ADDR}/ready"
        if check_health_endpoint "$STANDALONE_METRICS_ADDR"; then
            echo -e "    状态: ${GREEN}healthy${NC}"
        else
            echo -e "    状态: ${RED}unhealthy${NC}"
        fi
    fi

    if [[ "$mode" == "cluster" || "$mode" == "all" ]]; then
        echo "  集群版:"
        for i in "${!TMUX_CLUSTER_SESSIONS[@]}"; do
            local node="${TMUX_CLUSTER_SESSIONS[$i]}"
            local metrics_addr="${CLUSTER_METRICS_ADDRS[$i]}"
            local bolt_port="${CLUSTER_BOLT_PORTS[$i]}"
            echo "    ${node}:"
            echo "      Bolt 端口: ${REMOTE_HOST}:${bolt_port}"
            echo "      Metrics: http://${metrics_addr}/ready"
            if check_health_endpoint "$metrics_addr"; then
                echo -e "      状态: ${GREEN}healthy${NC}"
            else
                echo -e "      状态: ${RED}unhealthy${NC}"
            fi
        done
    fi

    log_separator
}
