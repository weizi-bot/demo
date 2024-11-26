#!/bin/bash

# 检查是否提供参数，否则进入交互模式
if [ "$#" -lt 2 ]; then
    echo "参数不足，进入交互模式..."
    read -p "请输入 IPv6 前缀 (例如 2602:fb94:aa::/48 或 2602:fb94:aa:fc58::/64): " PREFIX
    read -p "请输入要生成的 IP 数量: " COUNT
    read -p "请输入网卡名称 (例如 eth0): " INTERFACE
else
    PREFIX=$1
    COUNT=$2
    INTERFACE=$3
fi

# 自动提取子网掩码
SUBNET_MASK=$(echo "$PREFIX" | cut -d'/' -f2)
if [ -z "$SUBNET_MASK" ]; then
    echo "错误: 未提供有效的子网掩码，请检查 IPv6 前缀格式。"
    exit 1
fi

# 提取固定前缀
FIXED_SEGMENTS=$((SUBNET_MASK / 16))  # 固定段数
IFS=: read -r -a PREFIX_PARTS <<< "$(echo "$PREFIX" | cut -d'/' -f1)"

# 补齐固定部分
FIXED_PARTS=("${PREFIX_PARTS[@]}")
for ((i=${#FIXED_PARTS[@]}; i<FIXED_SEGMENTS; i++)); do
    FIXED_PARTS+=("0")
done

# 检查固定部分是否正确
if [ "${#FIXED_PARTS[@]}" -ne "$FIXED_SEGMENTS" ]; then
    echo "错误: IPv6 前缀的固定部分不正确。"
    exit 1
fi

# 计算随机段数
RANDOM_SEGMENTS=$((8 - FIXED_SEGMENTS))

# 初始化统计变量
SUCCESS_COUNT=0
FAIL_COUNT=0

echo "固定前缀: $(IFS=:; echo "${FIXED_PARTS[*]}")"
echo "子网掩码: /$SUBNET_MASK"
echo "随机段数: $RANDOM_SEGMENTS"

# 生成随机 IPv6 地址并添加
for ((i=1; i<=COUNT; i++)); do
    # 生成随机后缀
    RANDOM_SUFFIX=""
    for ((j=1; j<=RANDOM_SEGMENTS; j++)); do
        RANDOM_SUFFIX+=$(printf ":%04x" $((RANDOM%65536)))
    done

    # 拼接完整地址
    IP=$(IFS=:; echo "${FIXED_PARTS[*]}")"$RANDOM_SUFFIX/$SUBNET_MASK"

    # 输出生成的 IPv6 地址
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
