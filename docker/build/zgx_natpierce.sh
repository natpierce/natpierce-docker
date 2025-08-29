#!/bin/sh

# ANSI 转义码
# \033[32m: 绿色
# \033[33m: 黄色
# \033[31m: 红色
# \033[0m: 重置颜色

LOG_INFO() {
  printf "\033[32m[INFO] $(date +"%Y-%m-%d %H:%M:%S")\033[0m %s\n" "$1"
}

LOG_WARN() {
  printf "\033[33m[WARN] $(date +"%Y-%m-%d %H:%M:%S")\033[0m %s\n" "$1"
}

LOG_ERROR() {
  printf "\033[31m[ERROR] $(date +"%Y-%m-%d %H:%M:%S")\033[0m %s\n" "$1" >&2
}

version_file="/natpierce/version.txt"  # 这是版本文件的路径
app_file="/natpierce/natpierce" #这是程序文件的路径

# 检查当前IP转发状态
current_state=$(cat /proc/sys/net/ipv4/ip_forward)

if [ "$current_state" -eq 1 ]; then
  LOG_INFO "IP转发已经开启。"
else
  LOG_WARN "IP转发未开启，正在开启..."
  echo 1 > /proc/sys/net/ipv4/ip_forward
  if [ "$(cat /proc/sys/net/ipv4/ip_forward)" -eq 1 ]; then
    LOG_INFO "IP转发已成功开启。"
  else
    LOG_ERROR "IP转发开启失败。"
  fi
fi

if /usr/sbin/iptables -L >/dev/null 2>&1; then
  LOG_INFO "nftables后端"
  export iptables_mode="nftables"
elif /usr/sbin/iptables-legacy -L >/dev/null 2>&1; then
  LOG_INFO "legacy后端"
  export iptables_mode="legacy"
else
  LOG_ERROR "请检查容器是否启用特权模式"
  exit 1
fi

install /version/iptables.sh /usr/local/bin/iptables
install /version/iptables.sh /usr/local/bin/iptables-nft
install /version/iptables.sh /usr/local/bin/iptables-legacy


# 添加iptables规则
# 检查第一条规则是否存在
if ! iptables -C FORWARD -i eth0 -o natpierce -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null; then
 iptables -A FORWARD -i eth0 -o natpierce -m state --state RELATED,ESTABLISHED -j ACCEPT
 LOG_INFO "添加了第一条iptables规则。"
fi

# 检查第二条规则是否存在
if ! iptables -C FORWARD -i natpierce -o eth0 -j ACCEPT 2>/dev/null; then
 iptables -A FORWARD -i natpierce -o eth0 -j ACCEPT
 LOG_INFO "添加了第二条iptables规则。"
fi

iptables -V

#更新

# 网站的URL
url="https://www.natpierce.cn/tempdir/info/version.html"

if [ "x${update}" = "xtrue" ]; then
    LOG_INFO "开始获取官网最新版本号"
    version=$(wget -qO- "$url")
    if [ -n "${version}" ]; then
        LOG_INFO "获取当前版本号: ${version}"
    else
        LOG_ERROR "无法找到版本号"
        exit 1
    fi
elif [ "x${update}" = "xfalse" ]; then
    if [ "x${customversion}" = "xnull" ]; then
        LOG_ERROR "错误: customversion 不能为 null"
        exit 1
    else
        LOG_WARN "使用自定义版本号"
        version="${customversion}"
    fi
else
    LOG_ERROR "错误: update 的值必须是 'true' 或 'false'"
    exit 1
fi

LOG_INFO "使用版本号: ${version}"

# 定义基础URL
base_url="https://natpierce.oss-cn-beijing.aliyuncs.com/linux"

# 获取系统架构
arch=$(uname -m)

# 根据架构获取文件名
case "$arch" in
  x86_64)
    file="natpierce-amd64-v${version}.tar.gz"
    ;;
  aarch64)
    file="natpierce-arm64-v${version}.tar.gz"
    ;;
  armv7*)
    file="natpierce-arm32-v${version}.tar.gz"
    ;;
  *)
    LOG_ERROR "不支持的架构: $arch"
    exit 1
    ;;
esac

# 构建完整的下载URL
URL="${base_url}/${file}"

# 检查版本文件是否存在且内容是否与当前版本一致
if [ -f "$version_file" ] && [ "$(cat "$version_file")" = "$version" ] && [ -f "$app_file" ]; then
    LOG_INFO "版本文件存在且内容与当前版本一致。"
    version_txt=$(cat "$version_file")
    LOG_INFO "本地版本号为$version_txt"
else
    wget -O natpierce.tar.gz $URL
    if [ -s natpierce.tar.gz ] && [ $(stat -c%s natpierce.tar.gz) -gt 1024 ]; then
      LOG_INFO "下载 natpierce 包成功。"
    
      # 解压 natpierce 包
      if tar -xzvf natpierce.tar.gz natpierce; then
          rm natpierce.tar.gz
          LOG_INFO "解压 natpierce 包成功。"
      else
          LOG_ERROR "解压 natpierce 包失败。"
          exit 1
      fi
    else
      LOG_ERROR "下载natpierce包失败，请检查网络连接！！！"
      exit 1
    fi
    # 移动 natpierce 二进制文件到工作目录
    mkdir -p "/natpierce/"
    if mv natpierce /natpierce/natpierce; then
        LOG_INFO "natpierce 二进制文件已成功移动到工作目录。"
        chmod +x /natpierce/natpierce
        echo "$version" > "/natpierce/version.txt"
    else
        LOG_ERROR "移动 natpierce 二进制文件失败。"
        exit 1
    fi
fi

#检测tun的存在
if [ -c /dev/net/tun ] && [ -r /dev/net/tun ] && [ -w /dev/net/tun ]; then
  LOG_INFO "/dev/net/tun 设备存在且可读写，支持组网模式"
else
  LOG_WARN "/dev/net/tun 设备不可用，仅支持映射模式，组网模式不可用"
fi

#检测是否host模式
if ip link show docker0 >/dev/null 2>&1; then
    LOG_INFO "当前是host"
else
    LOG_WARN "不是host"
fi

cat << EOF

=================================================
          natpierce 容器启动 - 重要提示
=================================================

感谢您使用 natpierce！

为确保服务正常运行，请注意以下几点：

1.  [容器权限] 本容器需要修改系统网络设置，因此必须以特权模式
    (--privileged) 或拥有 NET_ADMIN 能力启动。
    示例: docker run -d --privileged ...

2.  [Web 端口] 您可以通过环境变量 'webdkh' 自定义 Web 服务的端口。
    示例: docker run -d -e webdkh=33272 ...

3.  [访问地址] Web 服务默认监听容器内的 0.0.0.0。
    - 若在 Docker 主机上访问，请使用 'localhost' 或 '127.0.0.1'。
    - 若从其他设备访问，请使用 Docker 主机的局域网 IP 地址。

4.  [故障排除] 访问失败时，请检查：
    - 使用桥接模式时 端口是否已正确映射到主机 (-p 参数)。
    - Docker Desktop for Mac/Windows 用户，请确保在设置开启host网络支持。
    - 主机防火墙是否放行了相应端口。

5.  [项目支持] 如果本项目对您有帮助，欢迎在 GitHub 上给我们一个 star！
    项目地址: https://github.com/natpierce/natpierce-docker

=================================================
EOF


/natpierce/natpierce -p $webdkh
