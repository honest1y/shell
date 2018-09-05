#!/bin/bash
# auth:kaliarch
# version:v1.0
# func:JAVA 1.6 1.7 1.8 安装

# 定义安装目录、及日志信息
. /etc/init.d/functions
[ $(id -u) != "0" ] && echo "Error: You must be root to run this script" && exit 1
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
download_path=/tmp/tmpdir/
install_log_name=install_java.log
env_file=/etc/profile.d/java.sh
install_log_path=/var/log/appinstall/
install_path=/usr/local/

clear
echo "##########################################"
echo "#                                        #"
echo "#      安装 JAVA 1.6 1.7 1.8             #"
echo "#                                        #"
echo "##########################################"
echo "1: Install java-1.6"
echo "2: Install java-1.7"
echo "3: Install java-1.8"
echo "4: EXIT"
# 选择安装软件版本
read -p "Please input your choice:" softversion

# 传入内容,格式化内容输出,可以传入多个参数,用空格隔开
output_msg() {
    for msg in $*;do
        action $msg /bin/true
    done
}

# 判断命令是否存在,第一个参数 $1 为判断的命令,第二个参数为提供该命令的yum 软件包名称
check_yum_command() {
        output_msg "命令检查：$1"
        hash $1 &> /dev/null
        if [ $? -eq 0 ];then
            echo "`date +%F' '%H:%M:%S` $1 命令检测完成" >> ${install_log_path}${install_log_name} && return 0
        else
            yum -y install $2 >/dev/null 2>&1
        fi
}

# 判断目录是否存在,传入目录绝对路径,可以传入多个目录
check_dir() {
    echo "----------------------------目录检测-------------------------------"
    for dirname in $*;do
        [ -d $1 ] || mkdir -p $dirname >/dev/null 2>&1
        output_msg "目录检查：${dirname}"
        echo "`date +%F' '%H:%M:%S` $dirname 目录检测完成" >> ${install_log_path}${install_log_name}
    done
}

# 下载文件并解压至安装目录,传入url链接地址
download_file() {
    output_msg "下载源码包"
    mkdir -p $download_path 
    for file in $*;do
        wget $file -c -P $download_path &> /dev/null
        if [ $? -eq 0 ];then
           echo "`date +%F' '%H:%M:%S` $file 下载成功">>${install_log_path}${install_log_name}
        else
           echo "`date +%F' '%H:%M:%s` $file 下载失败">>${install_log_path}${install_log_name} && exit 1
        fi
    done
}


# 解压文件,可以传入多个压缩文件绝对路径,用空格隔开,解压至安装目录
extract_file() {
   output_msg "解压源码"
   for file in $*;do
       if [ "${file##*.}" == "gz" ];then
           tar -zxf $file -C $install_path && echo "`date +%F' '%H:%M:%S` $file 解压成功">>${install_log_path}${install_log_name}
       elif [ "${file##*.}" == "zip" ];then
           unzip -q $file -d $install_path && echo "`date +%F' '%H:%M:%S` $file 解压失败">>${install_log_path}${install_log_name}
       else
           echo "`date +%F' '%H:%M:%S` $file type error, extrac fail!">>${install_log_path}${install_log_name} && exit 1
       fi
    done
}

# 配置环境变量,第一个参数为添加环境变量的绝对路径
config_env() {
    output_msg "环境变量配置"
    echo "export PATH=\$PATH:$1" >${env_file}
    source ${env_file} && echo "`date +%F' '%H:%M:%S` 软件安装完成!">> ${install_log_path}${install_log_name}

}



main() {
	check_dir $install_log_path $install_path
	check_yum_command wget wget
	check_yum_command unzip unzip
	download_file $URL

	for filename in `ls $download_path`;do
		extract_file ${download_path}$filename
	done
	software_name=`ls ${install_path} | grep jdk1`
	ln -s ${install_path}${software_name} ${install_path}java
	config_env ${install_path}java/bin
	rm -fr ${download_path}
}
case ${softversion} in
	1)
		URL="https://anchnet-script.oss-cn-shanghai.aliyuncs.com/jdk/jdk-6u45-linux-x64.bin"
		check_dir $install_log_path $install_path
		check_yum_command wget wget
		check_yum_command unzip unzip
		download_file $URL
		chmod +x $download_path/jdk-6u45-linux-x64.bin
		sh ${download_path}jdk-6u45-linux-x64.bin &> /dev/null
		output_msg "解源码包"
		mv /root/jdk1.6.0_45 /usr/local/java
		config_env ${install_path}java/bin
		rm -fr ${download_path}

	;;
	2)
		URL="https://anchnet-script.oss-cn-shanghai.aliyuncs.com/jdk/jdk-7u80-linux-x64.gz"
		main
	;;
	3)
		URL="https://anchnet-script.oss-cn-shanghai.aliyuncs.com/jdk/jdk-8u144-linux-x64.gz"
		main
	;;
	4)
		exit 0
	;;
	*)
		echo "input Error! Place input{1|2|3|4}"
		exit 1
esac
