#!/bin/bash
# date:2018-08-10
# install_vsftpd
. /etc/init.d/functions
[ $(id -u) != "0" ] && echo -e "\033[31mError: You must be root to run this script\033[0m" && exit 1
#Check install status
sys_version=`rpm -q centos-release|cut -d- -f3`
echo -e "\033[33mChecking...\033[0m"
rpm -q vsftpd &> /dev/null
[ $? -eq 0 ] && echo -e "\033[31mVsftpd had installed,exit...\033[0m" && exit 1

clear
echo "##########################################"
echo "#                                        #"
echo "#          安装 vsftpd                   #"
echo "#                                        #"
echo "##########################################"
echo "1: Install vsftpd"
echo "2: EXIT"
read -p "Please input your choice:" softversion

install() {
	echo "----------------------------安装中-------------------------------"
	yum install vsftpd -y &> /dev/null
}
config() {
	echo "----------------------------配置中-------------------------------"
	cat >/etc/vsftpd/vsftpd.conf <<EOF
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
xferlog_enable=YES
connect_from_port_20=YES
xferlog_std_format=YES
chroot_local_user=YES
listen=YES
pam_service_name=vsftpd
userlist_enable=YES
tcp_wrappers=YES
guest_enable=YES
guest_username=ftp
user_config_dir=/etc/vsftpd/vconf
pasv_enable=YES
pasv_min_port=30001
pasv_max_port=30005
userlist_deny=NO
EOF
	touch /etc/vsftpd/account.txt
	[ ! -d /etc/vsftpd/vconf ] && mkdir /etc/vsftpd/vconf
	db_load -T -thash -f /etc/vsftpd/account.txt /etc/vsftpd/account.db
	cp /etc/pam.d/vsftpd /etc/pam.d/vsftpd.bak
	> /etc/pam.d/vsftpd
	cat >/etc/pam.d/vsftpd <<EOF
auth 	   required     /lib64/security/pam_userdb.so db=/etc/vsftpd/account
account    required     /lib64/security/pam_userdb.so db=/etc/vsftpd/account
EOF
	[ $? -eq 0 ] && action "安装vsftpd" /bin/true || action "安装vsftpd" /bin/false
	if [ ${sys_version} == "7" ];then
		systemctl start vsftpd
	elif [ ${sys_version} == "6" ];then
		/etc/init.d/vsftpd start &> /dev/null
	fi
	netstat -tunlp | grep vsftpd &> /dev/null
	[ $? -eq 0 ] && action "启动服务" /bin/true || action "启动服务" /bin/false
}
main() {
	install
	config
}

case ${softversion} in
	1)
		main
	;;
	2)
		exit 0
	;;
	*)
		echo "input Error! Place input{1|2|3|4}"
		exit 1
esac
