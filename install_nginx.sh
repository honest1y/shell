#!/bin/bash
# CentOS 6|7 已测试
# Time: 2018-8-10
# install_nginx

. /etc/init.d/functions
[ $(id -u) != "0" ] && echo "Error: You must be root to run this script" && exit 1
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
install_log_name=install_nginx.log
env_file=/etc/profile.d/nginx.sh
install_log_path=/var/log/appinstall/
download_path=/tmp/tmpdir/
install_path=/usr/local/
src_path=/usr/local/src/
nginx_dir=/usr/local/nginx
zlib_dir=/usr/local/zlib
pcre_dir=/usr/local/pcre
openssl_dir=/usr/local/openssl
sys_version=`rpm -q centos-release|cut -d- -f3`


clear
echo "##########################################"
echo "#                                        #"
echo "#      安装 Nginx 1.12 1.14 1.15         #"
echo "#                                        #"
echo "##########################################"
echo "1: Install Nginx-1.12"
echo "2: Install Nginx-1.14"
echo "3: Install Nginx-1.15"
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
	        echo "`date +%F' '%H:%M:%S` 环境安装成功">>${install_log_path}${install_log_name} && return 0
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
           tar -zxf $file -C ${src_path} && echo "`date +%F' '%H:%M:%S` $file 解压成功" >> ${install_log_path}${install_log_name}
       elif [ "${file##*.}" == "zip" ];then
           unzip -q $file -d ${src_path} && echo "`date +%F' '%H:%M:%S` $file 解压失败" >> ${install_log_path}${install_log_name}
       else
           echo "`date +%F' '%H:%M:%S` $file type error, extrac fail!" >> ${install_log_path}${install_log_name} && exit 1
       fi
    done
}

# 配置环境变量,第一个参数为添加环境变量的绝对路径
config_env() {
    ok_msg "环境变量配置"
    echo "export PATH=\$PATH:$1" >${env_file}
    source ${env_file} && echo "`date +%F' '%H:%M:%S` 软件安装完成!">> ${install_log_path}${install_log_name}

}

# 编译Nginx函数
compile_nginx() {
	echo '----------------------------安装Nginx------------------------------'
	cd ${src_path}${nginx_name}
	id nginx &> /dev/null
	USER=`echo $?`
	if [ $USER -eq 1 ];then
	    useradd -s /sbin/nologin -M  nginx
	fi
	echo "`date +%F' '%H:%M:%S` 用户添加完成!">> ${install_log_path}${install_log_name}
	ok_msg "Nginx用户"
	./configure --prefix=${nginx_dir} --sbin-path=${nginx_dir}/sbin/nginx --conf-path=${nginx_dir}/conf/nginx.conf --lock-path=/var/lock/nginx.lock --error-log-path=${nginx_dir}/logs/error.log --http-log-path=${nginx_dir}/logs/access.log --pid-path=${nginx_dir}/nginx.pid   --user=nginx --group=nginx --with-http_ssl_module --with-http_flv_module --with-http_stub_status_module --with-http_gzip_static_module   --with-pcre=${src_path}${pcre_name} --with-zlib=${src_path}${zlib_name} --with-openssl=${src_path}${openssl_name} &> /dev/null
	if [ $? -eq 0 ];then
        ok_msg "编译Nginx"
        echo "`date +%F' '%H:%M:%S` 编译成功!">> ${install_log_path}${install_log_name}
	else
        error_msg "编译Nginx"
        echo "`date +%F' '%H:%M:%S` 编译失败!">> ${install_log_path}${install_log_name}
        exit 1
	fi
	make &> /dev/null
	make install &> /dev/null
	wget -O /etc/init.d/nginx https://anchnet-script.oss-cn-shanghai.aliyuncs.com/nginx/nginx &> /dev/null
	chmod a+x /etc/init.d/nginx
	if [ ${sys_version} == "7" ];then
		chkconfig --add nginx
		systemctl start nginx
	elif [ ${sys_version} == "6" ];then
		/etc/init.d/nginx start &> /dev/null
	fi
	ok_msg "安装Nginx"
	echo "`date +%F' '%H:%M:%S` Nginx安装完成!">> ${install_log_path}${install_log_name}
	netstat -tunlp | grep nginx &> /dev/null
	[ $? -eq 0 ] && ok_msg "启动Nginx" || erro_msg "启动Nginx"
}

# 编译OpenSSL函数
compile_openssl() {
	echo '----------------------------安装OpenSSL----------------------------'
	cd ${src_path}
	cp -r ${openssl_name} ${install_path}
	ok_msg "安装OpenSSL"
	echo "`date +%F' '%H:%M:%S` OpenSSL安装完成!">> ${install_log_path}${install_log_name}
}

# 编译Zlib函数
compile_zlib() {
	echo '----------------------------安装Zlib-------------------------------'
	cd ${src_path}${zlib_name}
	./configure --prefix=${zlib_dir} &> /dev/null
	make &> /dev/null
	make install &> /dev/null
	ok_msg "安装zlib"
	echo "`date +%F' '%H:%M:%S` Zlib安装完成!">> ${install_log_path}${install_log_name}
}

# 编译Pcre函数
compile_pcre() {
	echo '----------------------------安装Pcre-------------------------------'
	cd ${src_path}${pcre_name}
	./configure --prefix=${pcre_dir} &> /dev/null
	make &> /dev/null
	make install &> /dev/null
	ok_msg "安装pcre"
	echo "`date +%F' '%H:%M:%S` pcre安装完成!">> ${install_log_path}${install_log_name}
}
#主函数
main() {
	ZLIB="https://anchnet-script.oss-cn-shanghai.aliyuncs.com/nginx/zlib-1.2.11.tar.gz"
	OPENSSL="https://anchnet-script.oss-cn-shanghai.aliyuncs.com/nginx/openssl-1.0.1g.tar.gz"
	PCRE="https://anchnet-script.oss-cn-shanghai.aliyuncs.com/nginx/pcre-8.40.tar.gz"
	check_dir $src_path $install_log_path $install_path $download_path $nginx_dir $zlib_dir $pcre_dir $openssl_dir
	check_yum_command wget wget
	check_yum_command unzip unzip
	base_yum_install make cmake gcc gcc-c++  flex bison file libtool libtool-libs autoconf libjpeg libjpeg-devel libpng libpng-devel libpng10 libpng10-devel gd gd-devel freetype freetype-devel libxml2 libxml2-devel  zlib-devel glib2 glib2-devel bzip2 bzip2-devel libevent libevent-devel ncurses ncurses-devel curl curl-devel e2fsprogs e2fsprogs-devel krb5 krb5-devel libidn libidn-devel  openssl-devel gettext gettext-devel ncurses-devel gmp-devel pspell-devel unzip libcap lsof
	download_file $URL Nginx
	download_file $ZLIB zlib
	download_file $PCRE pcre
	download_file $OPENSSL openssl
	for filename in `ls $download_path`;do
	    extract_file ${download_path}$filename ${filename}
	done
	nginx_name=`ls ${src_path} | grep nginx`
	pcre_name=`ls ${src_path} | grep pcre`
	zlib_name=`ls ${src_path} | grep zlib`
	openssl_name=`ls ${src_path} | grep openssl`
	compile_pcre
	compile_zlib
	compile_openssl
	compile_nginx
	rm -fr ${download_path}
	config_env ${nginx_dir}/sbin
}

case ${softversion} in
	1)
		URL="https://anchnet-script.oss-cn-shanghai.aliyuncs.com/nginx/nginx-1.12.2.tar.gz"
		main
	;;
	2)
		URL="https://anchnet-script.oss-cn-shanghai.aliyuncs.com/nginx/nginx-1.14.0.tar.gz"
		main
	;;
	3)
		URL="https://anchnet-script.oss-cn-shanghai.aliyuncs.com/nginx/nginx-1.15.2.tar.gz"
		main
	;;
	4)
		exit 0
	;;
	*)
		echo "input Error! Place input{1|2|3|4}"
		exit 1
esac
