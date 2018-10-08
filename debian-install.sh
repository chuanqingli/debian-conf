#!/bin/bash

<<'COMMENT'
知识点：
sed跨行替换
dirname,readlink,which,head
COMMENT

install-soft(){
    pkgs=(

        # 输入法
	    fcitx fcitx-table-wbpy fcitx-config-gtk
        # 编辑器
        vim-gtk emacs25 eclipse
        # ftp
        filezilla
        # 版本控制
        git subversion
        # 邮箱
        thunderbird
        zsh curl
        # 远程服务器
        xrdp vnc4server
        # 远程桌面
        rdesktop
        openssh-server
    )

    apt-get install ${pkgs[*]}
}

config-ssh(){
    checkok=`grep "^[ ]*PasswordAuthentication yes" /etc/ssh/ssh_config`
    if [[ ! ${checkok} =~ "PasswordAuthentication" ]];then
        echo "PasswordAuthentication yes">>/etc/ssh/ssh_config
    fi

    checkok=`grep "^[ ]*PermitRootLogin yes" /etc/ssh/sshd_config`
    if [[ ! ${checkok} =~ "PermitRootLogin" ]];then
        echo "PermitRootLogin yes">>/etc/ssh/sshd_config
    fi

    systemctl enable ssh
    systemctl enable sshd
    systemctl restart ssh
    systemctl restart sshd
}

config-zsh(){
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
    echo "ZSH_THEME plugins 节点多的话，请自行删除。两节点要加在source \$ZSH/oh-my-zsh.sh之前。"

    sed -i 's/^ZSH_THEME=.*$/ZSH_THEME="ys"/g' ~/.zshrc
    # 跨行替换
    sed -i ":begin; /^plugins=(/,/)/ { /)/! { $! { N; b begin }; }; s/plugins=(.*)/plugins=(git autojump zsh-autosuggestions)/; };" ~/.zshrc
}

config-chrome-lastpass(){
    srcdir=/home/bak/soft/zip
    fname=lpchrome_linux
    dstdir=/opt/google/chrome/${fname}
    # 没下载过就要下载
    if [[ ! -e ${srcdir}/${fname}.zip ]];then
        wget https://lastpass.com/${fname}.crx -O ${srcdir}/${fname}.zip
    fi
    
    mkdir -p ${dstdir}
    cp ${srcdir}/${fname}.zip ${dstdir}
    unzip ${dstdir}/${fname}.zip -d ${dstdir}
    rm ${dstdir}/${fname}.zip
}

config-wps-font(){
    srcdir=/home/bak/soft/zip
    dstdir=/usr/share/fonts
    fname=wps_symbol_fonts

    cp ${srcdir}/${fname}.zip ${dstdir}
    unzip ${dstdir}/${fname}.zip -d ${dstdir}
    rm ${dstdir}/${fname}.zip
    rundir=`pwd`
    cd ${dstdir}
    # 执行以下命令,生成字体的索引信息：
    mkfontscale && mkfontdir && fc-cache
    cd ${rundir}
}

config-jdk6(){
    srcdir=/home/bak/soft/bin
    dstdir=/opt/java
    fname=jdk-6u45-linux-x64

    mkdir -p ${dstdir}
    cp ${srcdir}/${fname}.bin ${dstdir}

    rundir=`pwd`
    cd ${dstdir}
    bash ./${fname}.bin
    rm ${fname}.bin
    cd ${rundir}

    for ename in "java" "javac" "jar";do
        #数字越大，优先级越高
        update-alternatives --install /usr/bin/${ename} ${ename} /opt/java/jdk1.6.0_45/bin/${ename} 9000
    done

#    return

#    checkok=`grep "^JAVA_HOME" /etc/profile`
#    if [[ ${checkok} =~ "JAVA_HOME" ]];then
#        return
#    fi
#
#    #echo "export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which javac))))">>/etc/profile
#    echo 'export JAVA_HOME=$(dirname $(dirname $(update-alternatives --list java|head -n 1)))'>>/etc/profile
#    echo 'export JRE_HOME=$JAVA_HOME/jre'>>/etc/profile
#    echo 'export CLASSPATH=.:$JAVA_HOME/lib:$JRE_HOME/lib'>>/etc/profile
#    echo 'export PATH=$JAVA_HOME/bin:$PATH'>>/etc/profile
}

config-hosts(){
   checkok=`grep "^#tianya-hosts" /etc/hosts`
   if [[ ${checkok} =~ "tianya-hosts" ]];then
       return
   fi

   echo '#tianya-hosts'>>/etc/hosts

   cat /home/bak/debianconf/tianya-hosts>>/etc/hosts
}

source ../shell-func/git-func.sh
$1
