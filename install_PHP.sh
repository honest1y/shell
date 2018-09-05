#!/bin/bash
#Auto Install PHP (5.6|7.0|7.1)

. /etc/init.d/functions
clear
#Root test
[ $(id -u) != "0" ] && echo "Error: You must be root to run this script" && exit 1
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
install_log_name=install_php.log
env_file=/etc/profile.d/php.sh
install_log_path=/var/log/appinstall/
download_path=/tmp/tmpdir/
install_path=/usr/local/
src_path=/usr/local/src/
php_dir=/usr/local/php
sys_version=`rpm -q centos-release|cut -d- -f3`


clear
echo "##########################################"
echo "#                                        #"
echo "#        安装 PHP 5.6 7.0 7.1            #"
echo "#                                        #"
echo "##########################################"
echo "1: Install PHP-5.6"
echo "2: Install PHP-7.0"
echo "3  Install PHP-7.1"
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
	        echo "`date +%F' '%H:%M:%S` Install completed">>${install_log_path}${install_log_name} && return 0
	else
		echo "`date +%F' '%H:%M:%S` Install fail!">>${install_log_path}${install_log_name} && return 1
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
    echo "`date +%F' '%H:%M:%S` 目录检查 check success!" >> ${install_log_path}${install_log_name}
}

# 下载文件并解压至安装目录,传入url链接地址
download_file() {
    ok_msg "下载源码包：$2"
    mkdir -p $download_path 
    wget $1 -c -P $download_path &> /dev/null
    if [ $? -eq 0 ];then
       echo "`date +%F' '%H:%M:%S` $2 download success!">>${install_log_path}${install_log_name}
    else
       echo "`date +%F' '%H:%M:%s` $2 download fail!">>${install_log_path}${install_log_name} && exit 1
    fi
}

# 解压文件,可以传入多个压缩文件绝对路径,用空格隔开,解压至安装目录
extract_file() {
   ok_msg "解压源码包：$2"
   cd ${download_path}
   for file in $1;do
       if [ "${file##*.}" == "gz" ];then
           tar -zxf $file -C ${src_path} && echo "`date +%F' '%H:%M:%S` $file extrac success!,path is $src_path">>${install_log_path}${install_log_name}
       elif [ "${file##*.}" == "zip" ];then
           unzip -q $file -d ${src_path} && echo "`date +%F' '%H:%M:%S` $file extrac success!,path is $src_path">>${install_log_path}${install_log_name}
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
# 编译PHP函数
compile_php() {
	echo '------------------------------安装PHP-----------------------------'
	cd ${src_path}${php_name}
	./configure --prefix=${php_dir}  --exec-prefix=${php_dir}  --bindir=${php_dir}/bin --sbindir=${php_dir}/sbin --includedir=${php_dir}/include --libdir=${php_dir}/lib/php --mandir=${php_dir}/php/man  --with-config-file-path=${php_dir}/etc --with-mhash --with-openssl  --with-mysqli --with-pdo-mysql --with-gd --with-iconv --with-zlib --enable-zip --enable-inline-optimization  --enable-shared --enable-xml --enable-bcmath --enable-shmop --enable-sysvsem --enable-mbregex --enable-mbstring --enable-ftp --enable-gd-native-ttf --enable-pcntl --enable-sockets --with-xmlrpc --enable-soap --without-pear --with-gettext --enable-session --with-curl --with-jpeg-dir --with-freetype-dir --enable-opcache --enable-fpm --with-fpm-user=www --with-fpm-group=www --without-gdbm --disable-fileinfo &> /dev/null
	
	if [ $? -eq 0 ];then
        ok_msg "编译PHP"
        echo "`date +%F' '%H:%M:%S` 编译成功!">> ${install_log_path}${install_log_name}
	else
        error_msg "编译PHP"
        echo "`date +%F' '%H:%M:%S` 编译失败!">> ${install_log_path}${install_log_name}
        exit 1
	fi
	make &> /dev/null
	make install &> /dev/null
	if [ $? -eq 0 ];then
        ok_msg "安装PHP"
        echo "`date +%F' '%H:%M:%S` 编译成功!">> ${install_log_path}${install_log_name}
	else
        error_msg "安装PHP"
        echo "`date +%F' '%H:%M:%S` 编译失败!">> ${install_log_path}${install_log_name}
        exit 1
	fi
	/bin/cp php.ini-production ${php_dir}/etc/php.ini
	ok_msg "安装PHP-FPM"
	[ ! -f /etc/init.d/php-fpm ] && wget -O /etc/init.d/php-fpm https://anchnet-script.oss-cn-shanghai.aliyuncs.com/php/php-fpm &> /dev/null
	chmod a+x /etc/init.d/php-fpm
	id www &> /dev/null
	USER=`echo $?`
	if [ $USER -eq 1 ];then
	    useradd -s /sbin/nologin -M  www
	fi
	rm -fr /etc/php.ini
	ln -s ${phpdir}/etc/php.ini /etc/php.ini
	cd ${php_dir}/etc && /bin/cp php-fpm.conf.default php-fpm.conf
	[ -d ${php_dir}/etc/php-fpm.d ] && cd php-fpm.d && /bin/cp www.conf.default www.conf
	if [ ${sys_version} == "7" ];then
		chkconfig --add php-fpm
		systemctl start php-fpm
	elif [ ${sys_version} == "6" ];then
		/etc/init.d/php-fpm start &> /dev/null
	fi
	netstat -tunlp | grep php-fpm &> /dev/null
	[ $? -eq 0 ] && ok_msg "启动服务" || error_msg "启动服务"
	echo "`date +%F' '%H:%M:%S` PHP安装完成!">> ${install_log_path}${install_log_name}
}	

main() {
	check_dir $src_path $install_log_path $install_path $download_path $php_dir
	check_yum_command wget wget
	check_yum_command unzip unzip
	base_yum_install make cmake gcc gcc-c++  flex bison file libtool libtool-libs autoconf libjpeg libjpeg-devel libpng libpng-devel libpng10 libpng10-devel gd gd-devel freetype freetype-devel libxml2 libxml2-devel  zlib-devel glib2 glib2-devel bzip2 bzip2-devel libevent libevent-devel ncurses ncurses-devel curl curl-devel e2fsprogs e2fsprogs-devel krb5 krb5-devel libidn libidn-devel  openssl-devel gettext gettext-devel ncurses-devel gmp-devel pspell-devel unzip libcap lsof curl-devel
	download_file $URL PHP
	for filename in `ls $download_path`;do
	    extract_file ${download_path}$filename ${filename}
	done
	php_name=`ls ${src_path} | grep php`
	compile_php
	rm -fr ${download_path}
	config_env ${php_dir}/bin

}


case ${softversion} in 
		1)
			URL="https://anchnet-script.oss-cn-shanghai.aliyuncs.com/php/php-5.6.31.tar.gz"
			main
		;;
		2)
			URL="https://anchnet-script.oss-cn-shanghai.aliyuncs.com/php/php-7.0.22.tar.gz"
			main
		;;
		3)
			URL="https://anchnet-script.oss-cn-shanghai.aliyuncs.com/php/php-7.1.8.tar.gz"
			main
		;;
		4)
			exit 0
		;;
		*)
			echo "input Error! Place input{1|2|3|4}"
			exit 1
esac
