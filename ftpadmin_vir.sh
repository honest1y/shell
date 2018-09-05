#!/bin/bash

. /etc/init.d/functions
clear
function menu1 {
cat << EOF
----------------------------------------------------
|******              FTP admin           ***********|
|******	                                 ***********|
----------------------------------------------------

功能列表:
	1.增加用户
	2.更改目录
	3.修改密码
	4.删除用户
	5.查看用户
	6.退出
EOF
read -p "Please Input Your Choice: " choice
case ${choice} in
	1)
		AddUser
	;;
	2)
		ChangeDirectory
	;;
	3)
		ChangePassword
	;;
	4)
		DelUser
	;;
	5)
		ListUser
		menu2
	;;
	quit|q|exit)
		exit 0
esac
}
function menu2 {
cat << EOF
功能列表:
	1.增加用户
	2.更改目录
	3.修改密码
	4.删除用户
	5.查看用户
	6.退出
EOF
read -p "Please Input Your Choice: " choice
case ${choice} in
	1)
		AddUser
	;;
	2)
		ChangeDirectory
	;;
	3)
		ChangePassword
	;;
	4)
		DelUser
	;;
	5)
		clear
		ListUser
		menu2
	;;
	quit|q|exit)
		exit 7
esac
}
function User_name {
read -p "请输入用户名: " name
grep ${name} /etc/vsftpd/account.txt &> /dev/null
while [ $? -eq 0 ]
do
	echo -e "\033[31m错误,用户 ${name} 已经存在.\033[0m"
	read -p "请再次输入用户名: " name 
	grep ${name} /etc/vsftpd/account.txt &> /dev/null
done
}
function Check_user {
read -p "请输入用户名: " name
grep ${name} /etc/vsftpd/account.txt &> /dev/null
while [ $? -eq 1 ]
do
        echo -e "\033[31m错误,用户 ${name} 不存在.\033[0m"
        read -p "请再次输入用户名: " name
	grep ${name} /etc/vsftpd/account.txt &> /dev/null
done
}
function User_pwd {
read -p "请输入用户 ${name} 的密码: " password1
while [ ${password1} = ${name} ]
do
	echo -e "\033[31m错误,密码不能与用户名相同\033[0m"
	read -p "请输入用户 ${name} 的密码: " password1
done
read -p "请再次输入用户 ${name} 的密码: " password2
while [ ${password1} != ${password2} ]
do
	echo -e "\033[31m错误,两次输入密码不一致.\033[0m"
	read -p "请输入用户 ${name} 的密码: " password1
	read -p "请再次输入用户 ${name} 的密码: " password2
done
}
function User_dir {
read -p "请输入FTP目录(默认：/data/ftp/): " directory
while [ -d /data/ftp/${directory} ]
do 
	echo -e "\033[31m错误,目录 ${directory} 已经存在.\033[0m"
	read -p "请重新输入FTP目录: " directory
done
}	
function AddUser {
User_name
User_pwd
User_dir
mkdir -p /data/ftp/${directory}
echo ${name} >> /etc/vsftpd/account.txt
echo ${password1} >> /etc/vsftpd/account.txt
touch /etc/vsftpd/vconf/${name}
cat >/etc/vsftpd/vconf/${name} <<EOF
local_root=/data/ftp/${directory}
anon_upload_enable=YES
anon_mkdir_write_enable=YES
anon_other_write_enable=YES
EOF
echo ${name} >> /etc/vsftpd/user_list
/usr/bin/db_load -T -thash -f /etc/vsftpd/account.txt /etc/vsftpd/account.db
cat /etc/vsftpd/account.txt | grep ${name} &> /dev/null
status2=$?
chown ftp.ftp /data/ftp/${directory}
if [ ${status2} -eq 0 ];then

	echo -e "[${name}] 创建 \033[32m完成!\033[0m"
	echo -e "用 户 名 : \033[34m${name}\033[0m"
	echo -e "密   码  : \033[34m${password1}\033[0m"
	echo -e "FTP目 录 : \033[34m/data/ftp/${directory}\033[0m"
else
	echo -e "\033[31m${name} 创建失败！\033[0m"
	rm -fr /data/ftp/${directory}
	rm -fr /etc/vsftpd/vconf/${name}
	sed -i "/${name}/,+1d" /etc/vsftpd/account.txt
fi
}
function ChangeDirectory {
Current_user
Check_user
User_dir
mkdir /data/ftp/${directory}
sed -i "1clocal_root=/data/ftp/${directory}" /etc/vsftpd/vconf/${name}
chown ftp.ftp /data/ftp/${directory}
service vsftpd restart &> /dev/null
echo -e "用户\033[34m${name}\033[0m 的家目录已经修改为 \033[34m/data/ftp/${directory}\033[0m"
}

function ChangePassword {
Current_user
Check_user
User_pwd
sed -i "s#`cat /etc/vsftpd/account.txt | grep -A1 ${name} | sed -n '2p'`#${password1}#g" /etc/vsftpd/account.txt
/usr/bin/db_load -T -thash -f /etc/vsftpd/account.txt /etc/vsftpd/account.db
echo -e "用户 \033[34m${name}\033[0m 的密码已经修改为\033[34m${password1}\033[0m"
}

function DelUser {
Current_user
Check_user
echo -e "\033[31m确定删除用户 ${name}?\033[0m"
echo -e "\033[31m任意键确认删除,Ctrl+c退出.\033[0m"
read -n 1
sed -i "/${name}/,+1d" /etc/vsftpd/account.txt
sed -i "/${name}/d" /etc/vsftpd/user_list
rm -fr /etc/vsftpd/vconf/${name}
/usr/bin/db_load -T -thash -f /etc/vsftpd/account.txt /etc/vsftpd/account.db
echo -e "用户\033[34m${name}\033[0m 已删除."
echo -e "\033[31m注意:\033[0m为确保数据安全，用户 ${name} 的家目录未删除，请自行处理."
}

function Current_user {
user_list=`cat /etc/vsftpd/account.txt | sed -n '1p'`
echo -e "已开通用户:
\033[34m${user_list}\033[0m"
}
function ListUser {
Current_user
if [ "${user_list}" = "" ];then
	echo -e "\033[31m未发现FTP用户.\033[0m"
	exit
fi
Check_user
directory=`head -1 /etc/vsftpd/vconf/${name} | awk -F "=" '{print $2}'`
if [ -d ${directory} ];then
	Size=`du -sh ${directory}/ | awk '{print $1}'`
else
	Size="未发现"
fi
echo -e "用户名:\033[34m${name}\033[0m       目录:\033[34m${directory}\033[0m       大小:\033[34m${Size}\033[0m"
}
menu1
