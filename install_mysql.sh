#!/bin/bash
# CentOS 6|7 已测试
# Time: 2018-8-10
# install_mysql
# CentOS 6已适配,7服务启动脚本未适配
. /etc/init.d/functions
[ $(id -u) != "0" ] && echo "Error: You must be root to run this script" && exit 1
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
install_log_name=install_mysql.log
env_file=/etc/profile.d/mysql.sh
install_log_path=/var/log/appinstall/
download_path=/tmp/tmpdir/
install_path=/usr/local/
src_path=/usr/local/src/
mysql_dir=/usr/local/mysql
mysql_data=/usr/local/mysql/data
sys_version=`rpm -q centos-release|cut -d- -f3`


clear
echo "##########################################"
echo "#                                        #"
echo "#        安装 MySQL 5.5 5.6 5.7          #"
echo "#                                        #"
echo "##########################################"
echo "1: Install MySQL-5.5"
echo "2: Install MySQL-5.6"
echo "3: Install MySQL-5.7"
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
       echo "`date +%F' '%H:%M:%S` $2 下载完成">>${install_log_path}${install_log_name}
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
           tar -zxf $file -C ${src_path} && echo "`date +%F' '%H:%M:%S` $file 解压完成">>${install_log_path}${install_log_name}
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
# 内存检测
mem_check() {
    Memory=`free -m | grep Mem:|awk -F' ' '{print$2}'`
    if [ ${Memory} -lt 1500 ];then
    	error_msg "内存检查"
	echo '虚拟机内存小于2G可能会导致编译出错，建议提升机器配置.'
	read -p "是否继续？ [Y/N]" mem
	if [ ${mem} == "y" -o ${mem} == "Y" ];then
		continue
	else
		exit 0
	fi
    fi
}
# 编译MySQL函数
compile_mysql() {
	echo '----------------------------安装MySQL------------------------------'
	cd ${src_path}${mysql_name}
	id mysql &> /dev/null
	USER=`echo $?`
	if [ $USER -eq 1 ];then
		groupadd mysql
	    useradd -g mysql mysql -s /bin/false
		chown -R mysql:mysql /usr/local/mysql/data
	fi
	echo "`date +%F' '%H:%M:%S` 用户添加完成!">> ${install_log_path}${install_log_name}
	ok_msg "MySQL用户"
	if [ ${softversion} == "1" ];then
		cmake . -DCMAKE_INSTALL_PREFIX=${mysql_dir} -DMYSQL_DATADIR=${mysql_data} -DSYSCONFDIR=/etc &> /dev/null
		STATUS=$?
		[ $? -eq 0 ] && ok_msg "Cmake完成" || error_msg "Cmake完成"
	elif [ ${softversion} == "2" ];then
		cmake . -DCMAKE_INSTALL_PREFIX=${mysql_dir} -DMYSQL_DATADIR=${mysql_data} -DSYSCONFDIR=/etc &> /dev/null
		STATUS=$?
		[ $? -eq 0 ] && ok_msg "Cmake完成" || error_msg "Cmake完成"
	elif [ ${softversion} == "3" ];then
		boost_url="https://anchnet-script.oss-cn-shanghai.aliyuncs.com/mysql/boost_1_59_0.tar.gz"
		download_file ${boost_url} boost
		tar -zxf /tmp/tmpdir/boost_1_59_0.tar.gz -C /usr/local/
		cmake . -DCMAKE_INSTALL_PREFIX=${mysql_dir} -DMYSQL_DATADIR=${mysql_data} -DSYSCONFDIR=/etc -DWITH_BOOST=/usr/local/boost_1_59_0 &> /dev/null
		STATUS=$?
		[ $? -eq 0 ] && ok_msg "Cmake完成" || error_msg "Cmake完成"
	fi
	if [ ${STATUS} -eq 0 ];then
        echo "`date +%F' '%H:%M:%S` Cmake成功!">> ${install_log_path}${install_log_name}
	else
        error_msg "编译MySQL"
        echo "`date +%F' '%H:%M:%S` Cmake失败!">> ${install_log_path}${install_log_name} && exit 1
        exit 1
	fi
	make
	make install &> /dev/null
	mv /etc/my.cnf /etc/my.cnf.bak
	if [ ${softversion} == "1" ];then
		/bin/cp ${mysql_dir}/support-files/my-medium.cnf /etc/my.cnf
	elif [ ${softversion} == "2" ];then
		/bin/cp ${mysql_dir}/support-files/my-default.cnf /etc/my.cnf
	elif [ ${softversion} == "3" ];then
		wget -O /etc/my.cnf https://anchnet-script.oss-cn-shanghai.aliyuncs.com/mysql/my-medium.cnf &> /dev/null
	fi
	if [ ${softversion} == "3" ];then
		continue
	else
		echo "datadir = ${mysql_data}" >> /etc/my.cnf
		echo "basedir = ${mysql_dir}" >> /etc/my.cnf
	fi
	if [ ${softversion} == "3" ];then
		${mysql_dir}/bin/mysqld --initialize-insecure --user=mysql --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data &> /dev/null
		[ $? -eq 0 ] && ok_msg "DB初始化" || error_msg "DB初始化"
	else
		chmod +x ./scripts/mysql_install_db
		./scripts/mysql_install_db --user=mysql --basedir=${mysql_dir} --datadir=/usr/local/mysql/data &> /dev/null
		[ $? -eq 0 ] && ok_msg "DB初始化" || error_msg "DB初始化"
	fi
	echo "`date +%F' '%H:%M:%S` MySQL db初始化安装完成!">> ${install_log_path}${install_log_name}
	cp ./support-files/mysql.server /etc/rc.d/init.d/mysqld
	chmod 755 /etc/init.d/mysqld
	if [ ${sys_version} == "7" ];then
		chkconfig --add mysqld
		systemctl start mysqld
	elif [ ${sys_version} == "6" ];then
		/etc/init.d/mysqld start &> /dev/null
	fi
	ok_msg "安装MySQL"
	echo "`date +%F' '%H:%M:%S` MySQL安装完成!">> ${install_log_path}${install_log_name}
	netstat -tunlp | grep mysql &> /dev/null
	[ $? -eq 0 ] && ok_msg "启动MySQL" || error_msg "启动MySQL"
}

#主函数
main() {
	mem_check
	check_dir $src_path $install_log_path $install_path $download_path $mysql_dir $mysql_data
	check_yum_command wget wget
	check_yum_command unzip unzip
	base_yum_install install make gcc gcc-c++ cmake bison-devel  ncurses-devel vimbison libgcrypt perl
	download_file $URL MySQL
	for filename in `ls $download_path`;do
	    extract_file ${download_path}$filename ${filename}
	done
	mysql_name=`ls ${src_path} | grep mysql`
	compile_mysql
	rm -fr ${download_path}
	config_env ${mysql_dir}/bin
}

case ${softversion} in
	1)
		URL="https://anchnet-script.oss-cn-shanghai.aliyuncs.com/mysql/mysql-5.5.57.tar.gz"
		main
	;;
	2)
		URL="https://anchnet-script.oss-cn-shanghai.aliyuncs.com/mysql/mysql-5.6.37.tar.gz"
		main
	;;
	3)
		URL="https://anchnet-script.oss-cn-shanghai.aliyuncs.com/mysql/mysql-5.7.19.tar.gz"
		main
	;;
	4)
		exit 0
	;;
	*)
		echo "input Error! Place input{1|2|3|4}"
		exit 1
esac
