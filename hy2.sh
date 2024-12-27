#!/bin/bash

# 使用systemctl检查hysteria服务状态
if systemctl is-active --quiet hysteria-server; then
  echo "hysteria2 运行中"
else
  echo "hysteria2 已停止"
fi
echo "请选择一个操作："
echo "1 启动服务"
echo "2 查看日志"
echo "3 安装服务"
read -p "请输入选项（1/2/3）: " action

case $action in
  1)
    echo "正在启动服务..."
    systemctl restart hysteria-server.service
    sleep 5
    # 使用systemctl检查hysteria服务状态
if systemctl is-active --quiet hysteria-server; then
  echo "hysteria2 运行中"
else
  echo "hysteria2 已停止"
fi
sleep 3
    sudo journalctl --vacuum-time=1s --unit=hysteria-server.service
    journalctl -u hysteria-server -n 10 --no-pager
    ;;
  2)
    echo "正在查看日志..."
    sudo journalctl --vacuum-time=1s --unit=hysteria-server.service
    journalctl -u hysteria-server.service
    ;;
  3)
    echo "正在安装服务..."
    bash <(curl -fsSL https://get.hy2.sh/)
    systemctl enable hysteria-server.service
# 询问用户值
read -p "请输入已解析域名: " ym_value
read -p "请输入端口(直接回车则443): " port_value
# 检查用户是否输入了端口
if [ -z "$port_value" ]; then
  # 用户没有输入端口，默认
  port_value=443
  echo "设置端口443"
else
  echo "设置端口$port_value"
fi
# 询问用户是否使用端口跳跃  
read -p "是否使用端口跳跃？(y/n): " use_port_jump  
  
# 检查用户输入  
case $use_port_jump in  
    [Yy]* )  
        # 用户选择使用端口跳跃  
        read -p "请输入端口范围（例如 4000:5000），不输入则默认为 4000:5000: " port_range  
          
        # 检查用户是否输入了端口范围  
        if [ -z "$port_range" ]; then  
            port_range="4000:5000"  
        fi  
          
        # 验证端口范围格式（这里只做简单检查，具体实现可能需要根据需求调整）  
        if ! [[ "$port_range" =~ ^[0-9]+:[0-9]+$ ]]; then  
            echo "端口范围格式错误，应为 '起始端口:结束端口' 的形式。"  
            exit 1  
        fi  
          
        # 执行iptables命令  
        iptables -t nat -A PREROUTING -i eth0 -p udp --dport $port_range -j REDIRECT --to-ports   $port_value
        echo "iptables规则已设置，将UDP端口 $port_range 重定向到端口 $port_value。"  
        ;;  
    [Nn]* )  
        # 用户选择不使用端口跳跃  
        echo "跳过端口跳跃设置。"  
        ;;  
    * )  
        echo "无效输入，请输入 'y' 或 'n'。"  
        exit 1  
        ;;  
esac
read -p "请输入密码: (直接回车则随机密码)" key_value
# 检查用户是否输入了密码
if [ -z "$key_value" ]; then
  # 用户没有输入密码，生成随机20位密码
  key_value=$(< /dev/urandom tr -dc 'A-Za-z0-9!' | head -c 20)
  echo "随机生成的密码为: $key_value"
else
  echo "您输入的密码为: $key_value"
fi

# 将密码赋值给变量
password=$key_value
# 生成一个6个字母的随机字符串
mail=$(tr -dc 'a-zA-Z' </dev/urandom | head -c 6)
# 输出随机字符串
echo "随机生成的邮箱是: $mail@gmail.com"

#写入 config.yaml 文件
cat <<EOF > /etc/hysteria/config.yaml
listen: :$port_value

acme:
  domains:
    - $ym_value
  email: $mail@gmail.com

auth:
  type: password
  password: $password

masquerade:
  type: proxy
  proxy:
    url: https://www.runoob.com/
    rewriteHost: true
EOF

echo "安装完成"
sleep 3
sudo journalctl --vacuum-time=1s --unit=hysteria-server.service
systemctl restart hysteria-server.service
sleep 8
# 使用systemctl检查hysteria服务状态
if systemctl is-active --quiet hysteria-server; then
  echo "hysteria2 运行中"
else
  echo "hysteria2 已停止"
fi
sleep 3
journalctl -u hysteria-server -n 10 --no-pager
echo "复制并从剪切板导入:   hy2://$password@$ym_value:$port_value/#hy2-$ym_value   "
    ;;
  *)
    echo "无效输入，退出脚本。"
    exit 1
    ;;
esac
