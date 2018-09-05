#!/bin/bash
# CentOS 6|7 已测试
# Time: 2018-8-10
# install_nginx
# CentOS 6已适配,7服务启动脚本未适配
. /etc/init.d/functions
[ $(id -u) != "0" ] && echo "Error: You must be root to run this script" && exit 1
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
install_log_name=install_apache.log
env_file=/etc/profile.d/apache.sh
install_log_path=/var/log/appinstall/
download_path=/tmp/tmpdir/
install_path=/usr/local/
src_path=/usr/local/src/
apache_dir=/usr/local/apache2
apr_dir=/usr/local/apr
apr_util_dir=/usr/local/apr-util
sys_version=`rpm -q centos-release|cut -d- -f3`


clear
echo "##########################################"
echo "#                                        #"
echo "#        安装 Apache 2.2 2.4             #"
echo "#                                        #"
echo "##########################################"
echo "1: Install Apache-2.2"
echo "2: Install Apache-2.4"
echo "3: YUM(CentOS 6 For Ver2.2,CentOS 7 For Ver2.4)"
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
        echo "`date +%F' '%H:%M:%S` 命令检查 $1 ">>${install_log_path}${install_log_name} && return 0
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

# 编译Apache函数
compile_apache() {
	echo '----------------------------安装Apache-----------------------------'
	cd ${src_path}${apache_name}
	id www &> /dev/null
	USER=`echo $?`
	if [ $USER -eq 1 ];then
	    useradd -s /sbin/nologin -M  www
	fi
	echo "`date +%F' '%H:%M:%S` 用户添加完成!">> ${install_log_path}${install_log_name}
	ok_msg "Apache用户"
	./configure --prefix=${apache_dir} --with-apr=${apr_dir} --with-apr-util=${apr_util_dir} --with-ssl --enable-ssl --enable-module=so --enable-rewrite --enable-cgid --enable-cgi &> /dev/null
	if [ $? -eq 0 ];then
        ok_msg "编译Apache"
        echo "`date +%F' '%H:%M:%S` 编译成功!">> ${install_log_path}${install_log_name}
	else
        error_msg "编译Apache"
        echo "`date +%F' '%H:%M:%S` 编译失败!">> ${install_log_path}${install_log_name}
        exit 1
	fi
	make &> /dev/null
	make install &> /dev/null
	sed -i 's#User daemon#User www#g' ${apache_dir}/conf/httpd.conf
	sed -i 's#Group daemon#Group www#g' ${apache_dir}/conf/httpd.conf
	sed -i 's/#ServerName/ServerName/g' ${apache_dir}/conf/httpd.conf
	if [ ${sys_version} == "7" ];then
		wget -O /etc/init.d/httpd https://anchnet-script.oss-cn-shanghai.aliyuncs.com/httpd/httpd-7 &> /dev/null
	elif [ ${sys_version} == "6" ];then
		wget -O /etc/init.d/httpd https://anchnet-script.oss-cn-shanghai.aliyuncs.com/httpd/httpd &> /dev/null
	fi
	chmod a+x /etc/init.d/httpd
	if [ ${sys_version} == "7" ];then
		chkconfig --add httpd
		systemctl enable httpd &> /dev/null
		systemctl start httpd
	elif [ ${sys_version} == "6" ];then
		/etc/init.d/httpd start &> /dev/null
	fi
	ok_msg "安装Apache"
	echo "`date +%F' '%H:%M:%S` Apache安装完成!">> ${install_log_path}${install_log_name}
	netstat -tunlp | grep httpd &> /dev/null
	[ $? -eq 0 ] && ok_msg "启动Apache" || error_msg "启动Apache"
}

# 编译apr函数
compile_apr() {
	echo '----------------------------安装apr--------------------------------'
	cd ${src_path}${apr_name}
	./configure --prefix=${apr_dir} &> /dev/null
	make &> /dev/null
	make install &> /dev/null
	ok_msg "安装apr"
	echo "`date +%F' '%H:%M:%S` apr安装完成!">> ${install_log_path}${install_log_name}
}

# 编译apr_util函数
compile_apr_util() {
	echo '----------------------------安装apr-util----------------------------'
	cd ${src_path}${apr_util_name}
	./configure --prefix=${apr_util_dir} --with-apr=${apr_dir}/bin/apr-1-config &> /dev/null
	make &> /dev/null
	make install &> /dev/null
	ok_msg "安装apr-util"
	echo "`date +%F' '%H:%M:%S` apr-util安装完成!" >> ${install_log_path}${install_log_name}
}

#主函数
main() {
	APR="https://anchnet-script.oss-cn-shanghai.aliyuncs.com/httpd/apr-1.6.2.tar.gz"
	APR_UTILS="https://anchnet-script.oss-cn-shanghai.aliyuncs.com/httpd/apr-util-1.6.0.tar.gz"
	check_dir $src_path $install_log_path $install_path $download_path $apache_dir $apr_dir $apr_util_dir
	check_yum_command wget wget
	check_yum_command unzip unzip
	base_yum_install install expat-devel freetype-devel cmake  autoconf automake gcc gcc-c++ zlib-devel openssl openssl-devel pcre-devel gd  keyutils patch perl  mpfr cpp glibc libgomp libstdc++-devel ppl cloog-ppl keyutils-libs-devel libcom_err-devel libsepol-devel libselinux-devel krb5-devel zlib-devel libXpm* freetype libjpeg* libpng* php-common php-gd ncurses* libtool* libxml2 libxml2-devel patch
	download_file $URL Apache
	download_file $APR apr
	download_file ${APR_UTILS} apr-util
	for filename in `ls $download_path`;do
	    extract_file ${download_path}$filename ${filename}
	done
	apache_name=`ls ${src_path} | grep httpd`
	apr_name=`ls ${src_path} | grep apr`
	apr_util_name=`ls ${src_path} | grep apr-util`
	compile_apr
	compile_apr_util
	compile_apache
	rm -fr ${download_path}
	config_env ${apache_dir}/bin
}

case ${softversion} in
	1)
		URL="https://anchnet-script.oss-cn-shanghai.aliyuncs.com/httpd/httpd-2.2.34.tar.gz"
		main
	;;
	2)
		URL="https://anchnet-script.oss-cn-shanghai.aliyuncs.com/httpd/httpd-2.4.27.tar.gz"
		main
	;;
	3)
		
		base_yum_install install expat-devel freetype-devel cmake  autoconf automake gcc gcc-c++ zlib-devel openssl openssl-devel pcre-devel gd  keyutils patch perl  mpfr cpp glibc libgomp libstdc++-devel ppl cloog-ppl keyutils-libs-devel libcom_err-devel libsepol-devel libselinux-devel krb5-devel zlib-devel libXpm* freetype libjpeg* libpng* php-common php-gd ncurses* libtool* libxml2 libxml2-devel patch
		yum install httpd -y &> /dev/null
		if [ ${sys_version} == "7" ];then
			systemctl enable httpd &> /dev/null
			systemctl start httpd
		elif [ ${sys_version} == "6" ];then
			/etc/init.d/httpd start &> /dev/null
	fi
	;;
	4)
		exit 0
	;;
	*)
		echo "input Error! Place input{1|2|3|4}"
		exit 1
esac
