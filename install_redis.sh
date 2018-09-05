#!/bin/bash
# date:2018-08-10
# install_vsftpd
. /etc/init.d/functions
[ $(id -u) != "0" ] && echo -e "\033[31mError: You must be root to run this script\033[0m" && exit 1
install_log_name=install_redis.log
env_file=/etc/profile.d/redis.sh
install_log_path=/var/log/appinstall/
download_path=/tmp/tmpdir/
install_path=/usr/local/
src_path=/usr/local/src/
redis_dir=/usr/local/redis
sys_version=`rpm -q centos-release|cut -d- -f3`

clear
echo "##########################################"
echo "#                                        #"
echo "#          安装 Redis 4.0                #"
echo "#                                        #"
echo "##########################################"
echo "1: Yum     Install"
echo "2: Compile Install"
echo "3: EXIT"
read -p "Please input your choice:" softversion


# 传入内容,格式化内容输出,可以传入多个参数,用空格隔开
ok_msg() {
    for msg in $*;do
        action $msg /bin/true
    done
}
error_msg() {
    for msg in $*;do
        action $msg /bin/false
    done
}
base_yum_install() {
	echo '----------------------------环境安装-------------------------------'
	for package in $*;do
		yum install -y ${package} &> /dev/null
		ok_msg "安装软件包：${package}"
	done
	if [ $? -eq 0 ];then
	        echo "`date +%F' '%H:%M:%S` 环境安装完成">>${install_log_path}${install_log_name} && return 0
	else
		echo "`date +%F' '%H:%M:%S` 环境安装失败">>${install_log_path}${install_log_name} && return 1
	fi
}
check_dir() {
    echo '----------------------------目录检测-------------------------------'
    for dirname in $*;do
        [ -d ${dirname} ] || mkdir -p $dirname &> /dev/null
    	ok_msg "目录检查：${dirname}"
    done
    echo "`date +%F' '%H:%M:%S` 目录检查完成" >> ${install_log_path}${install_log_name}
}
check_yum_command() {
    ok_msg "命令检查：$1"
    hash $1 &> /dev/null
    if [ $? -eq 0 ];then
        echo "`date +%F' '%H:%M:%S` check command $1 ">>${install_log_path}${install_log_name} && return 0
    else
        yum -y install $2 >/dev/null 2>&1
    fi
}

# 下载文件并解压至安装目录,传入url链接地址
download_file() {
    ok_msg "下载源码包：$2"
    mkdir -p $download_path 
    wget $1 -c -P $download_path &> /dev/null
    if [ $? -eq 0 ];then
       echo "`date +%F' '%H:%M:%S` $2 下载完成">>${install_log_path}${install_log_name}
    else
       echo "`date +%F' '%H:%M:%s` $2 下载失败">>${install_log_path}${install_log_name} && exit 1
    fi
}
extract_file() {
   ok_msg "解压源码包：$2"
   cd ${download_path}
   for file in $1;do
       if [ "${file##*.}" == "gz" ];then
           tar -zxf $file -C ${src_path} && echo "`date +%F' '%H:%M:%S` $file 解压完成">>${install_log_path}${install_log_name}
       elif [ "${file##*.}" == "zip" ];then
           unzip -q $file -d ${src_path} && echo "`date +%F' '%H:%M:%S` $file 解压失败">>${install_log_path}${install_log_name}
       else
           echo "`date +%F' '%H:%M:%S` $file type error, extrac fail!">>${install_log_path}${install_log_name} && exit 1
       fi
    done
}
yum_install() {
	echo "----------------------------安装中-------------------------------"
	yum install epel-release -y &> /dev/null
	[ $? -eq 0 ] && ok_msg "安装EPEL" || error_msg "安装EPEL"
	yum install redis -y &> /dev/null
	[ $? -eq 0 ] && ok_msg "安装Redis" || error_msg "安装Redis"
	if [ ${sys_version} == "7" ];then
		systemctl start redis
	elif [ ${sys_version} == "6" ];then
		/etc/init.d/redis start &> /dev/null
	fi
	netstat -tunlp | grep 6379 &> /dev/null
	[ $? -eq 0 ] && ok_msg "启动Redis" || error_msg "启动Redis"
}

compile_install() {
	URL="https://anchnet-script.oss-cn-shanghai.aliyuncs.com/redis/redis-4.0.11.tar.gz"
	check_dir ${redis_dir} ${install_log_path} ${download_path} ${src_path}
	check_yum_command wget wget
	check_yum_command unzip unzip
	base_yum_install gcc gcc-c++ 
	download_file $URL Redis
	for filename in `ls $download_path`;do
	    extract_file ${download_path}$filename ${filename}
	done
	redis_name=`ls ${src_path} | grep redis`
	cd ${src_path}${redis_name}
	echo "----------------------------安装中---------------------------------"
	make PREFIX=${redis_dir} install &> /dev/null
	[ $? -eq 0 ] && ok_msg "make" || error_msg "make"
	/bin/cp redis.conf ${redis_dir}/bin/redis.conf
	echo "vm.overcommit_memory = 1" >> /etc/sysctl.conf
	echo never > /sys/kernel/mm/transparent_hugepage/enabled
	sysctl vm.overcommit_memory=1 &> /dev/null
	${redis_dir}/bin/redis-server ${redis_dir}/bin/redis.conf & &> /dev/null
	sleep 2
	netstat -tunlp | grep 6379 &> /dev/null
	[ $? -eq 0 ] && ok_msg "启动Redis" || error_msg "启动Redis"
	rm -fr ${download_path}
}

case ${softversion} in
	1)
		yum_install
	;;
	2)
		compile_install
	;;
	3)
		exit 0
	;;
	*)
		echo "input Error! Place input{1|2|3}"
		exit 1
esac
