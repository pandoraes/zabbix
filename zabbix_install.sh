#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS 6-7/Debian 6+/Ubuntu 14.04+
#	Description: Install the zabbix agent
#	Version: 1.0.0
#	Author: worms
#=================================================

sh_ver="1.0.0"
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"
Separator="——————————————————————————————"

check_root(){
	[[ $(id -u) != "0" ]] && echo -e "${Error} 当前账号非ROOT(或没有ROOT权限)，无法继续操作，请使用${Green_background_prefix} sudo su ${Font_color_suffix}来获取临时ROOT权限。" && exit 1
}
check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
	bit=`uname -m`
}
#添加用户
add_user(){
	groupadd zabbix
	useradd -g zabbix zabbix
}
#安装管理服务
install_zabbix_server(){
	unzip_pack
	yum install -y mysql mysql-server mysql-devel net-snmp-devel libxml2-devel libevent libevent-devel curl curl-devel
	./configure --prefix=/usr/local/zabbix-3.4/ --enable-server --enable-agent --with-mysql --with-net-snmp --with-libcurl --with-libxml2
	make install
	service mysqld restart
	read -p "请输入zabbix的mysql连接用户名: " zbuser
	read -p "请输入zabbix的mysql连接密码: " zbpassw
	mysql -u root -e"create database zabbix character set utf8 collate utf8_bin;"
	mysql -u root -e"grant all privileges on zabbix.* to ${zbuser}@localhost identified by '${zbpassw}';"
}
install_zabbix_proxy(){
	unzip_pack
	./configure --prefix=/usr/local/zabbix-3.4/ --enable-proxy --with-net-snmp --with-sqlite3 --with-ssh2
	make install
}
#安装agent
install_zabbix_agent(){
	read -p "请输入要zabbix服务主机的IP或者域名(例子www.waono.com): " IPAddress
	unzip_pack
	./configure --prefix=/usr/local/zabbix-3.4/ --enable-agent
	make install
}
select_version(){
	echo -e "请选择要使用的zabbix版本号
 ${Green_font_prefix} 1.${Font_color_suffix} zabbix-3.4.4
 ${Green_font_prefix} 2.${Font_color_suffix} zabbix-3.2.11
 ${Green_font_prefix} 3.${Font_color_suffix} zabbix-3.0.14" && echo
	stty erase '^H' && read -p "(默认: 1. zabbix-3.4.4):" select_ver
	[[ -z "${select_ver}" ]] && ssr_method="5"
	if [[ ${select_ver} == "1" ]]; then
		select_ver="zabbix-3.4.4"
	elif [[ ${select_ver} == "2" ]]; then
		select_ver="zabbix-3.2.11"
	elif [[ ${select_ver} == "3" ]]; then
		select_ver="zabbix-3.0.14"
	else
		select_ver="zabbix-3.4.4"
	fi
	echo && echo ${Separator} && echo -e "	版本 : ${Green_font_prefix}${select_ver}${Font_color_suffix}" && echo ${Separator} && echo
}
unzip_pack(){
	init_base
	select_version	
	downloader_zabbix
	tar zxf ${select_ver}.tar.gz
	cd ${select_ver}
}
init_base(){
	yum install -y pcre-devel
	add_user
}
downloader_zabbix(){
	wget -N --no-check-certificate https://raw.githubusercontent.com/pandoraes/zabbix/master/pack/${select_ver}.tar.gz
	
}
modify_file(){
	sed -i "s#Server=127.0.0.1#Server=${IPAddress}#" /usr/local/${select_ver}/etc/zabbix_agentd.conf
	sed -i "s#ServerActive=127.0.0.1#ServerActive=${IPAddress}#" /usr/local/${select_ver}/etc/zabbix_agentd.conf
	
}
check_root
check_sys
[[ ${release} != "debian" ]] && [[ ${release} != "ubuntu" ]] && [[ ${release} != "centos" ]] && echo -e "${Error} 脚本这个系统 ${release} !" && exit 1
echo -e "  zabbix 一键管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  ---- by worms ----

  ${Green_font_prefix}1.${Font_color_suffix} 安装 Zabbix Server
  ${Green_font_prefix}2.${Font_color_suffix} 安装 Zabbix Agent
  ${Green_font_prefix}3.${Font_color_suffix} 安装 Zabbix Proxy
  ${Green_font_prefix}4.${Font_color_suffix} 升级脚本
 "
echo && stty erase '^H' && read -p "请输入数字 [1-3]：" num
case "$num" in
	1)
	install_zabbix_server
	;;
	2)
	install_zabbix_proxy
	;;
	3)
	install_zabbix_agent
	;;
	*)
	echo -e "${Error} 请输入正确的数字 [1-3]"
	;;
esac