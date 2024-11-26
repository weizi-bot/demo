#!/bin/bash

# 检查参数
if [ "$#" -ne 3 ]; then
    echo "用法: $0 <IPv6前缀> <数量> <网卡名称>"
    echo "示例: $0 2001:475:35:3f4::6/64 1000 eth0"
    exit 1
fi

# 参数赋值
PREFIX=$1          # IPv6 前缀，例如 2001:475:35:3f4::/64
COUNT=$2           # 要生成的数量，例如 1000
INTERFACE=$3       # 网卡名称，例如 eth0

# 提取 IPv6 前缀的网络部分
NETWORK=$(echo "$PREFIX" | cut -d'/' -f1)
SUBNET_MASK=$(echo "$PREFIX" | cut -d'/' -f2)

# 检查前缀长度是否合理
if [ "$SUBNET_MASK" -ne 64 ]; then
    echo "目前仅支持 /64 的前缀。"
    exit 1
fi

# 生成并添加 IP 地址
for ((i=1; i<=COUNT; i++)); do
    # 生成随机后缀
    SUFFIX=$(printf "%x:%x:%x:%x" $((RANDOM%65536)) $((RANDOM%65536)) $((RANDOM%65536)) $((RANDOM%65536)))

    # 拼接完整 IPv6 地址
    IP="$NETWORK:$SUFFIX/$SUBNET_MASK"

    # 添加 IP 到网卡
    echo "添加 $IP 到网卡 $INTERFACE"
    sudo ip addr add "$IP" dev "$INTERFACE"

    # 检查命令是否成功
    if [ $? -ne 0 ]; then
        echo "添加 $IP 时出错，停止操作。"
        exit 1
    fi
done

echo "成功添加 $COUNT 个 IPv6 地址到网卡 $INTERFACE"
