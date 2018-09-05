#!/bin/bash
# CentOS 6|7 已测试
# Time: 2018-8-20
# install_postgresql
# CentOS 6|7已适配
. /etc/init.d/functions
[ $(id -u) != "0" ] && echo "Error: You must be root to run this script" && exit 1
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
install_log_name=install_postgresql.log
env_file=/etc/profile.d/postgresql.sh
install_log_path=/var/log/appinstall/
download_path=/tmp/tmpdir/
sys_version=`rpm -q centos-release|cut -d- -f3`


clear
echo "##########################################"
echo "#                                        #"
echo "#        安装 PostgreSQL 9.4 9.6 10      #"
echo "#                                        #"
echo "##########################################"
echo "1: Yum install PostgreSQL-9.4"
echo "2: Yum install PostgreSQL-9.6"
echo "3: Yum install PostgreSQL-10.5"
echo "4: EXIT"
# 选择安装软件版本
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
# 判断命令是否存在,第一个参数 $1 为判断的命令,第二个参数为提供该命令的yum 软件包名称
check_yum_command() {
    ok_msg "命令检查：$1"
    hash $1 &> /dev/null
    if [ $? -eq 0 ];then
        echo "`date +%F' '%H:%M:%S` check command $1 ">>${install_log_path}${install_log_name} && return 0
    else
        yum -y install $2 >/dev/null 2>&1
    fi
}

# 判断目录是否存在,传入目录绝对路径,可以传入多个目录
check_dir() {
    echo '----------------------------目录检测-------------------------------'
    for dirname in $*;do
        [ -d ${dirname} ] || mkdir -p $dirname &> /dev/null
    	ok_msg "目录检查：${dirname}"
    done
    echo "`date +%F' '%H:%M:%S` 目录检查完成" >> ${install_log_path}${install_log_name}
}

# 下载文件并解压至安装目录,传入url链接地址
download_file() {
    ok_msg "下载源码包：$2"
    mkdir -p $download_path 
    wget $1 -c -P $download_path &> /dev/null
    if [ $? -eq 0 ];then
       echo "`date +%F' '%H:%M:%S` $2 下载成功">>${install_log_path}${install_log_name}
    else
       echo "`date +%F' '%H:%M:%s` $2 下载失败">>${install_log_path}${install_log_name} && exit 1
    fi
}

# 解压文件,可以传入多个压缩文件绝对路径,用空格隔开,解压至安装目录
extract_file() {
   ok_msg "解压源码包：$2"
   cd ${download_path}
   for file in $1;do
       if [ "${file##*.}" == "gz" ];then
           tar -zxf $file -C ${src_path} && echo "`date +%F' '%H:%M:%S` $file 解压成功">>${install_log_path}${install_log_name}
       elif [ "${file##*.}" == "zip" ];then
           unzip -q $file -d ${src_path} && echo "`date +%F' '%H:%M:%S` $file 解压失败">>${install_log_path}${install_log_name}
       else
           echo "`date +%F' '%H:%M:%S` $file type error, extrac fail!">>${install_log_path}${install_log_name} && exit 1
       fi
    done
}

# 配置环境变量,第一个参数为添加环境变量的绝对路径
config_env() {
    ok_msg "环境变量配置"
    echo "export PATH=\$PATH:$1" >${env_file}
    source ${env_file} && echo "`date +%F' '%H:%M:%S` 软件安装完成!">> ${install_log_path}${install_log_name}

}


# 编译PostgreSQL函数
start_postgresql() {
	yum list | grep postgresql &> /dev/null
	if [ $? -eq 0 ];then
		 base_yum_install ${postsqlname}-server ${postsqlname} ${postsqlname}-libs
		 echo "`date +%F' '%H:%M:%S` 安装成功">> ${install_log_path}${install_log_name}
	else
		error_msg "安装"
		echo "No packages valid in yum repos,Please download repo files in https://yum.postgresql.org/"
		echo "`date +%F' '%H:%M:%S` No packages valid in yum repos,Please download repo files in https://yum.postgresql.org/">> ${install_log_path}${install_log_name}
		exit 1
	fi
	if [ ${sys_version} == "7" ];then
		if [ ${softversion} == "3" ];then
			/usr/pgsql-${version}/bin/postgresql-${version}-setup initdb &> /dev/null
		fi
		/usr/pgsql-${version}/bin/${postsqlname}-setup initdb &> /dev/null
	elif [ ${sys_version} == "6" ];then
		service ${servicename} initdb &> /dev/null
	fi
	ok_msg "初始化"
	if [ ${sys_version} == "7" ];then
		systemctl start ${servicename}
	elif [ ${sys_version} == "6" ];then
		/etc/init.d/${servicename} start &> /dev/null
	fi
	
	netstat -tunlp | grep 5432 &> /dev/null
	[ $? -eq 0 ] && ok_msg "启动PostgreSQL" || error_msg "启动PostgreSQL"
}

main() {
	check_dir ${download_path} ${install_log_path} ${pg_data}
	check_yum_command wget wget
	check_yum_command unzip unzip
	download_file ${URL} PostgreSQL
	rpm -ivh $download_path*.rpm --force &> /dev/null
	start_postgresql
	rm -fr ${download_path}
}

case ${softversion} in
	1)
		version="9.4"
		postsqlname="postgresql94"
		servicename="postgresql-9.4"
		if [ ${sys_version} == "7" ];then
			URL="https://anchnet-script.oss-cn-shanghai.aliyuncs.com/PostgreSQL/pgdg-centos7-9.4.noarch.rpm"
		elif [ ${sys_version} == "6" ];then
			URL="https://anchnet-script.oss-cn-shanghai.aliyuncs.com/PostgreSQL/pgdg-centos6-9.4.noarch.rpm"
		fi
		main
	;;
	2)
		version="9.6"
		postsqlname="postgresql96"
		servicename="postgresql-9.6"
		if [ ${sys_version} == "7" ];then
			URL="https://anchnet-script.oss-cn-shanghai.aliyuncs.com/PostgreSQL/pgdg-centos7-9.6.noarch.rpm"
		elif [ ${sys_version} == "6" ];then
			URL="https://anchnet-script.oss-cn-shanghai.aliyuncs.com/PostgreSQL/pgdg-centos6-9.6.noarch.rpm"
		fi
		main
	;;
	3)
		version="10"
		postsqlname="postgresql10"
		servicename="postgresql-10"
		if [ ${sys_version} == "7" ];then
			URL="https://anchnet-script.oss-cn-shanghai.aliyuncs.com/PostgreSQL/pgdg-centos7-10-2.noarch.rpm"
		elif [ ${sys_version} == "6" ];then
			URL="https://anchnet-script.oss-cn-shanghai.aliyuncs.com/PostgreSQL/pgdg-centos6-10-2.noarch.rpm"
		fi
		main
	;;
	4)
		exit 0
	;;
	*)
		echo "input Error! Place input{1|2|3}"
		exit 1
esac