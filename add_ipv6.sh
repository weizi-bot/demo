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

# 定义统计变量
SUCCESS_COUNT=0
FAIL_COUNT=0
SUCCESS_LIST=()
FAIL_LIST=()

# 生成 IPv6 地址列表
echo "正在生成 $COUNT 个唯一的 IPv6 地址..."
GENERATED_IPS=()
while [ "${#GENERATED_IPS[@]}" -lt "$COUNT" ]; do
    # 随机生成后缀，每段 4 位
    SUFFIX=$(printf "%04x:%04x:%04x:%04x" $((RANDOM%65536)) $((RANDOM%65536)) $((RANDOM%65536)) $((RANDOM%65536)))
    IP="$NETWORK:$SUFFIX/$SUBNET_MASK"

    # 确保地址唯一
    if [[ ! " ${GENERATED_IPS[*]} " =~ " $IP " ]]; then
        GENERATED_IPS+=("$IP")
    fi
done

echo "地址生成完成，开始添加到网卡 $INTERFACE..."

# 添加 IPv6 地址
for IP in "${GENERATED_IPS[@]}"; do
    sudo ip addr add "$IP" dev "$INTERFACE" 2>/dev/null
    if [ $? -eq 0 ]; then
        SUCCESS_LIST+=("$IP")
        ((SUCCESS_COUNT++))
    else
        FAIL_LIST+=("$IP")
        ((FAIL_COUNT++))
    fi
done

# 输出统计结果
echo "================ 添加完成 ================"
echo "总计生成: $COUNT"
echo "成功添加: $SUCCESS_COUNT"
echo "失败添加: $FAIL_COUNT"

if [ "$FAIL_COUNT" -gt 0 ]; then
    echo "失败的 IP 地址如下:"
    for FAIL_IP in "${FAIL_LIST[@]}"; do
        echo "  $FAIL_IP"
    done
fi
