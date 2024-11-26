#!/bin/bash

# 生成随机的二进制序列
function get_random_binary_segment() {
    local length=$1
    local binary=""
    for ((i=0; i<length; i++)); do
        binary+=$((RANDOM % 2))
    done
    echo "$binary"
}

# 转换十六进制段为二进制段
function segment_to_binary() {
    printf "%016d" "$(echo "obase=2; ibase=16; ${1:-0}" | bc)"
}

# 将 IPv6 地址转换为二进制
function convert_ipv6_to_binary() {
    local ipv6=$1
    local segments=($(echo "$ipv6" | tr ":" " "))
    local binary=""
    for segment in "${segments[@]}"; do
        binary+=$(segment_to_binary "$segment")
    done
    echo "$binary"
}

# 生成随机 IPv6 地址
function generate_ipv6_addresses() {
    local prefix=$1
    local count=$2
    local interface=$3

    local ipv6_prefix=$(echo "$prefix" | cut -d'/' -f1)
    local prefix_length=$(echo "$prefix" | cut -d'/' -f2)

    local binary_prefix=$(convert_ipv6_to_binary "$ipv6_prefix" | cut -c 1-"$prefix_length")
    local suffix_length=$((128 - prefix_length))

    local success_count=0
    local fail_count=0

    echo "正在生成 $count 个 IPv6 地址..."
    for ((i=0; i<count; i++)); do
        local random_suffix=$(get_random_binary_segment "$suffix_length")
        local binary_ipv6="${binary_prefix}${random_suffix}"

        # 转换二进制地址为 IPv6 格式
        local hex_ipv6=$(echo "$binary_ipv6" | awk '
        BEGIN { ORS="" }
        {
            for (i = 1; i <= length($0); i += 16) {
                printf "%x", "0b" substr($0, i, 16)
                if (i + 16 <= length($0)) {
                    printf ":"
                }
            }
        }')

        # 添加到网卡
        sudo ip addr add "${hex_ipv6}/$prefix_length" dev "$interface" 2>/dev/null
        if [ $? -eq 0 ]; then
            ((success_count++))
        else
            ((fail_count++))
        fi

        # 显示进度条
        printf "\r生成进度: [%d/%d]" "$((i + 1))" "$count"
    done
    echo
    echo "================ 添加完成 ================"
    echo "成功添加: $success_count"
    echo "失败添加: $fail_count"
}

# 脚本参数校验和交互
if [ $# -lt 3 ]; then
    echo "用法: $0 <IPv6前缀> <数量> <网卡名称>"
    echo "示例: $0 2602:fb94:aa:fc58::/64 100 eth0"
    exit 1
fi

generate_ipv6_addresses "$1" "$2" "$3"
