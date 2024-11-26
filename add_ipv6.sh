#!/bin/bash

# 如果参数不足，则提示交互式输入
if [ "$#" -lt 3 ]; then
    echo "检测到参数不足，进入交互模式。"
    read -p "请输入 IPv6 前缀 (例如 2001:475:35:3f4::/64): " PREFIX
    read -p "请输入要生成的 IP 数量: " COUNT
    read -p "请输入网卡名称 (例如 eth0): " INTERFACE
else
    PREFIX=$1
    COUNT=$2
    INTERFACE=$3
fi

# 检查输入是否为空
if [ -z "$PREFIX" ] || [ -z "$COUNT" ] || [ -z "$INTERFACE" ]; then
    echo "所有输入都不能为空！请重新运行脚本并提供完整信息。"
    exit 1
fi

# 提取 IPv6 前缀的网络部分
NETWORK=$(echo "$PREFIX" | cut -d'/' -f1)
SUBNET_MASK=$(echo "$PREFIX" | cut -d'/' -f2)

# 检查前缀长度是否合理
if [ "$SUBNET_MASK" -ne 64 ]; then
    echo "目前仅支持 /64 的前缀。"
    exit 1
fi

# 初始化统计变量
SUCCESS_COUNT=0
FAIL_COUNT=0
TOTAL=$COUNT

echo "正在生成和添加 $COUNT 个 IPv6 地址，请稍候..."

# 生成并添加 IPv6 地址
for ((i=1; i<=COUNT; i++)); do
    # 随机生成后缀，每段 4 位
    SUFFIX=$(printf "%04x:%04x:%04x:%04x" $((RANDOM%65536)) $((RANDOM%65536)) $((RANDOM%65536)) $((RANDOM%65536)))
    IP="$NETWORK:$SUFFIX/$SUBNET_MASK"

    # 添加 IP 地址到网卡
    sudo ip addr add "$IP" dev "$INTERFACE" 2>/dev/null
    if [ $? -eq 0 ]; then
        ((SUCCESS_COUNT++))
    else
        ((FAIL_COUNT++))
    fi

    # 更新进度条
    PROGRESS=$((i * 100 / TOTAL))
    printf "\r进度: [%-50s] %d%%" "$(printf '%*s' $((PROGRESS / 2)) '' | tr ' ' '#')" "$PROGRESS"
done

echo
echo "================ 添加完成 ================"
echo "总计生成: $COUNT"
echo "成功添加: $SUCCESS_COUNT"
echo "失败添加: $FAIL_COUNT"
