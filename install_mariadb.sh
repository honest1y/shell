#!/bin/bash
# CentOS 6|7 已测试
# Time: 2018-8-10
# install_mariadb
. /etc/init.d/functions
[ $(id -u) != "0" ] && echo "Error: You must be root to run this script" && exit 1
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
install_log_name=install_mariadb.log
env_file=/etc/profile.d/mariadb.sh
install_log_path=/var/log/appinstall/
download_path=/tmp/tmpdir/
install_path=/usr/local/
src_path=/usr/local/src/
mariadb_dir=/usr/local/mysql
mariadb_data=/usr/local/mysql/data
sys_version=`rpm -q centos-release|cut -d- -f3`


clear
echo "##########################################"
echo "#                                        #"
echo "#   安装 mariadb 5.5 10.1 10.2 10.3      #"
echo "#                                        #"
echo "##########################################"
echo "1: Install Mariadb-5.5"
echo "2: Install Mariadb-10.1"
echo "3: Install Mariadb-10.2"
echo "4: Install Mariadb-10.3"
echo "5: EXIT"
# 选择安装软件版本
read -p "Please input your choice:" softversion



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

# 编译mariadb函数
compile_mariadb() {
	echo '----------------------------安装MySQL------------------------------'
	cd ${src_path}${mariadb_name}
	id mysql &> /dev/null
	USER=`echo $?`
	if [ $USER -eq 1 ];then
		groupadd mysql
	    useradd -g mysql mysql -s /bin/false
		chown -R mysql:mysql /usr/local/mysql/data
	fi
	echo "`date +%F' '%H:%M:%S` 用户添加完成!">> ${install_log_path}${install_log_name}
	ok_msg "Mariadb用户"
	cmake . -DCMAKE_INSTALL_PREFIX=${mariadb_dir} -DMYSQL_DATADIR=${mariadb_data} -DSYSCONFDIR=/etc -DWITHOUT_TOKUDB=1 -DMYSQL_UNIX_ADDR=/tmp/mysql.sock -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci &> /dev/null
	if [ $? -eq 0 ];then
		ok_msg "Cmake完成"
		echo "`date +%F' '%H:%M:%S` Cmake成功!">> ${install_log_path}${install_log_name}
	else	
		error_msg "Cmake完成"
		echo "`date +%F' '%H:%M:%S` Cmake失败!">> ${install_log_path}${install_log_name}
		exit 1
	fi
	make
	make install &> /dev/null
	[ -f /etc/my.cnf ] && mv /etc/my.cnf /etc/my.cnf.bak
	/bin/cp ${mariadb_dir}/support-files/wsrep.cnf /etc/my.cnf
	chmod +x ./scripts/mysql_install_db
	./scripts/mysql_install_db --user=mysql --basedir=${mariadb_dir} --datadir=${mariadb_data} &> /dev/null
	[ $? -eq 0 ] && ok_msg "DB初始化" || error_msg "DB初始化"
	echo "`date +%F' '%H:%M:%S` Mariadb db初始化安装完成!">> ${install_log_path}${install_log_name}
	cp ./support-files/mysql.server /etc/rc.d/init.d/mysqld
	chmod 755 /etc/init.d/mysqld
	if [ ${sys_version} == "7" ];then
		chkconfig --add mysqld
		systemctl start mysqld
	elif [ ${sys_version} == "6" ];then
		/etc/init.d/mysqld start &> /dev/null
	fi
	ok_msg "安装Mariadb"
	echo "`date +%F' '%H:%M:%S` Mariadb安装完成!">> ${install_log_path}${install_log_name}
	netstat -tunlp | grep mysql &> /dev/null
	[ $? -eq 0 ] && ok_msg "启动Mariadb" || error_msg "启动Mariadb"
	echo "`date +%F' '%H:%M:%S` Mariadb启动成功!">> ${install_log_path}${install_log_name}
}

#主函数
main() {
	mem_check
	check_dir $src_path $install_log_path $install_path $download_path $mariadb_dir $mariadb_data
	check_yum_command wget wget
	check_yum_command unzip unzip
	base_yum_install install make gcc gcc-c++ cmake bison-devel ncurses-devel vimbison libgcrypt perl libaio-devel Judy Judy-devel openssl-devel libevent-devel bison
	download_file $URL Mariadb
	for filename in `ls $download_path`;do
	    extract_file ${download_path}$filename ${filename}
	done
	mariadb_name=`ls ${src_path} | grep mariadb`
	compile_mariadb
	rm -fr ${download_path}
	config_env ${mariadb_dir}/bin
}

case ${softversion} in
	1)
		URL="https://anchnet-script.oss-cn-shanghai.aliyuncs.com/mariadb/mariadb-5.5.61.tar.gz"
		main
	;;
	2)
		URL="https://anchnet-script.oss-cn-shanghai.aliyuncs.com/mariadb/mariadb-10.1.35.tar.gz"
		main
	;;
	3)
		URL="https://anchnet-script.oss-cn-shanghai.aliyuncs.com/mariadb/mariadb-10.2.17.tar.gz"
		main
	;;
	4)
		URL="https://anchnet-script.oss-cn-shanghai.aliyuncs.com/mariadb/mariadb-10.3.9.tar.gz"
		main
	;;
	5)
		exit 0
	;;
	*)
		echo "input Error! Place input{1|2|3|4}"
		exit 1
esac
