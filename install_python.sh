#!/bin/bash
# version:v1.0
# func:Python 3.5 3.6 3.7安装

# 定义安装目录、及日志信息
. /etc/init.d/functions
[ $(id -u) != "0" ] && echo "Error: You must be root to run this script" && exit 1
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
download_path=/tmp/tmpdir/
src_path=/usr/local/src/
install_log_name=install_python.log
env_file=/etc/profile.d/python.sh
install_log_path=/var/log/appinstall/
install_path=/usr/local/
python_dir=/usr/local/python3
sys_version=`rpm -q centos-release|cut -d- -f3`

clear
echo "##########################################"
echo "#                                        #"
echo "#          安装 Python 3.5 3.6 3.7       #"
echo "#                                        #"
echo "##########################################"
echo "1: Install Python-3.5"
echo "2: Install Python-3.6"
echo "3: Install Python-3.7"
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
        ok_msg "目录检查：${dirname}"
        echo "`date +%F' '%H:%M:%S` $dirname 目录检测完成" >> ${install_log_path}${install_log_name}
    done
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
   for file in $*;do
       if [ "${file##*.}" == "gz" ];then
           tar -zxf $file -C $src_path && echo "`date +%F' '%H:%M:%S` $file 解压成功">>${install_log_path}${install_log_name}
       elif [ "${file##*.}" == "zip" ];then
           unzip -q $file -d $src_path && echo "`date +%F' '%H:%M:%S` $file 解压失败">>${install_log_path}${install_log_name}
       elif [ "${file##*.}" == "tgz" ];then
		   tar -xf $file -C $src_path && echo "`date +%F' '%H:%M:%S` $file 解压成功">>${install_log_path}${install_log_name}
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


# Python编译函数
compile_python() {
    echo '----------------------------安装Python-----------------------------'
    cd ${src_path}${python_name}
    ./configure --prefix=${python_dir} --enable-shared CFLAGS=-fPIC &> /dev/null
    ok_msg "编译完成"
    echo "`date +%F' '%H:%M:%S` 编译完成!">> ${install_log_path}${install_log_name}
    make &> /dev/null
    make install &> /dev/null
    ok_msg "安装完成"
    ln -s ${python_dir}bin/python3 /usr/bin/python3
    ln -s ${python_dir}bin/pip3 /usr/bin/pip3
    ok_msg "软连接配置"
    echo "`date +%F' '%H:%M:%S` 软连接建立完成!">> ${install_log_path}${install_log_name}
    if [ ${softversion} == "1" ];then
    	/bin/cp libpython3.5m.so.1.0 /usr/lib64/
    	/bin/cp libpython3.5m.so.1.0 /usr/lib/
    elif [ ${softversion} == "2" ];then
    	/bin/cp libpython3.6m.so.1.0 /usr/lib64/
    	/bin/cp libpython3.6m.so.1.0 /usr/lib/
    elif [ ${softversion} == "3" ];then
    	/bin/cp libpython3.7m.so.1.0 /usr/lib64/
    	/bin/cp libpython3.7m.so.1.0 /usr/lib/
    fi
}
main() {
	check_dir $install_log_path $install_path ${python_dir} ${src_path} ${download_path}
    base_yum_install gcc gcc-c++ zlib zlib-devel bzip2 bzip2-devel ncurses ncurses-devel readline readline-devel openssl openssl-devel openssl-static xz lzma xz-devel sqlite sqlite-devel gdbm gdbm-devel
	check_yum_command wget wget
	check_yum_command unzip unzip
	download_file $URL Python
	for filename in `ls $download_path`;do
		extract_file ${download_path}$filename ${filename}
	done
	python_name=`ls ${src_path} | grep Python`
	compile_python
	config_env ${python_dir}/bin
	rm -fr ${download_path}
}
case ${softversion} in
	1)
		URL="https://anchnet-script.oss-cn-shanghai.aliyuncs.com/Python/Python-3.5.6.tgz"
		main
	;;
	2)
		URL="https://anchnet-script.oss-cn-shanghai.aliyuncs.com/Python/Python-3.6.4.tgz"
		main
	;;
	3)
		URL="https://anchnet-script.oss-cn-shanghai.aliyuncs.com/Python/Python-3.7.0.tgz"
		main
	;;
	4)
		exit 0
	;;
	*)
		echo "input Error! Place input{1|2|3|4}"
		exit 1
esac
