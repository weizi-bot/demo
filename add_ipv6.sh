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

# 提取子网掩码
SUBNET_MASK=$(echo "$PREFIX" | cut -d'/' -f2)
NETWORK=$(echo "$PREFIX" | cut -d'/' -f1)

# 验证子网掩码
if [ -z "$SUBNET_MASK" ] || [ "$SUBNET_MASK" -lt 1 ] || [ "$SUBNET_MASK" -gt 128 ]; then
    echo "错误: 子网掩码格式无效，请检查输入的 IPv6 前缀。"
    exit 1
fi

# 分割固定前缀为数组
IFS=: read -r -a PREFIX_PARTS <<< "$NETWORK"

# 初始化完整的 8 段数组
IPv6_ARRAY=(0 0 0 0 0 0 0 0)

# 填充固定部分到数组中
FIXED_SEGMENTS=$((SUBNET_MASK / 16))
for ((i=0; i<FIXED_SEGMENTS; i++)); do
    IPv6_ARRAY[$i]=${PREFIX_PARTS[$i]:-0}
done

# 初始化统计变量
SUCCESS_COUNT=0
FAIL_COUNT=0

echo "固定前缀: $(IFS=:; echo "${IPv6_ARRAY[*]:0:$FIXED_SEGMENTS}")"
echo "子网掩码: /$SUBNET_MASK"
echo "随机段数: $((8 - FIXED_SEGMENTS))"

# 开始生成随机 IPv6 地址
for ((i=1; i<=COUNT; i++)); do
    # 生成随机部分
    for ((j=FIXED_SEGMENTS; j<8; j++)); do
        IPv6_ARRAY[$j]=$(printf "%04x" $((RANDOM % 65536)))
    done

    # 拼接完整 IPv6 地址
    IP=$(IFS=:; echo "${IPv6_ARRAY[*]}")/$SUBNET_MASK

    # 输出生成的 IPv6 地址（调试用）
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
