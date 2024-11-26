#!/bin/bash

# 检查是否提供参数，否则进入交互模式
if [ "$#" -lt 3 ]; then
    echo "参数不足，进入交互模式..."
    read -p "请输入 IPv6 前缀 (例如 2602:fb94:aa:fc58::/64 或 2602:fb94:aa:fc58::1/64): " PREFIX
    read -p "请输入要生成的 IP 数量: " COUNT
    read -p "请输入网卡名称 (例如 eth0): " INTERFACE
else
    PREFIX=$1
    COUNT=$2
    INTERFACE=$3
fi

# 提取 IPv6 前缀的网络部分和子网掩码
NETWORK=$(echo "$PREFIX" | cut -d'/' -f1 | awk -F'::' '{print $1}')
SUBNET_MASK=$(echo "$PREFIX" | cut -d'/' -f2)

# 检查子网掩码是否支持
if [ "$SUBNET_MASK" -ne 64 ]; then
    echo "错误: 目前仅支持 /64 的 IPv6 前缀。"
    exit 1
fi

# 初始化统计变量
SUCCESS_COUNT=0
FAIL_COUNT=0

echo "正在生成 $COUNT 个 IPv6 地址并添加到网卡 $INTERFACE，请稍候..."

# 循环生成 IPv6 地址并添加
for ((i=1; i<=COUNT; i++)); do
    # 随机生成后缀，每段 4 位
    RANDOM_SUFFIX=$(printf "%04x:%04x:%04x:%04x" $((RANDOM%65536)) $((RANDOM%65536)) $((RANDOM%65536)) $((RANDOM%65536)))
    IP="$NETWORK:$RANDOM_SUFFIX/$SUBNET_MASK"

    # 输出生成的 IPv6 地址（用于调试）
    echo "生成地址: $IP"

    # 添加到网卡
    sudo ip addr add "$IP" dev "$INTERFACE" 2>/dev/null
    if [ $? -eq 0 ]; then
        ((SUCCESS_COUNT++))
    else
        ((FAIL_COUNT++))
    fi
done

echo
echo "================ 添加完成 ================"
echo "总计生成: $COUNT"
echo "成功添加: $SUCCESS_COUNT"
echo "失败添加: $FAIL_COUNT"
