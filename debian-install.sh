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
   if [[ -n ${checkok} ]];then
       return
   fi

   echo '#tianya-hosts'>>/etc/hosts

   cat /home/bak/debianconf/tianya-hosts>>/etc/hosts
}

config-deblist(){
    stable=`lsb_release -c --short`
    sourl='http://mirrors.163.com/'
    checkok=`grep ${sourl} /etc/apt/sources.list`
    if [[ -n ${checkok} ]];then
        return
    fi

    for ename in ${stable}/updates ${stable} ${stable}-updates ${stable}-backports;do
        pname='debian'
        if [[ ${ename} == ${stable}/updates ]];then
            pname='debian-security'
        fi
        echo "deb ${sourl}${pname}/ ${ename} main non-free contrib">>/etc/apt/sources.list
        echo "deb-src ${sourl}${pname}/ ${ename} main non-free contrib">>/etc/apt/sources.list
    done

    apt-get update && apt-get upgrade
}

get-hd-media(){
    vurl=http://mirrors.163.com/debian/dists/stable/main/installer-amd64/current/images/hd-media/
    mkdir -p gtk
    for ename in gtk/initrd.gz gtk/vmlinuz;do
        wget ${vurl}/${ename} -O ${ename}
    done
}

config-myiso(){
    mkdir -p /mnt/debinst
    debootstrap --arch amd64 stretch  /mnt/debinst http://mirrors.163.com/debian

}

#截图
convert-crop(){
    srcdir='/home/chuanqing/VirtualBox VMs/debian22/ttt'
    prefix='VirtualBox_debian22_21_10_2018_10_'
    suffix='.png'
    dstfname='test'

    pp0='1024x512+0+127'
    pp1='1024x55+0+584'

    fname="09_03 12_06"
    rundir=`pwd`

    cd "$srcdir"
    index=0
    vcmd=''

    for ppp in `ls|sort`;do
        index=$((index+1))

        kkk=$pp1
        if [[ $index == 1 ]];then
            kkk=$pp0
        fi

        convert ${ppp} -crop $kkk ${dstfname}${index}.png
        vcmd="${vcmd} ${dstfname}${index}.png"
    done



#    for ppp in ${fname};do
#        index=$((index+1))
#
#        kkk=$pp1
#        if [[ $index == 1 ]];then
#            kkk=$pp0
#        fi
#
#        convert ${prefix}${ppp}${suffix} -crop $kkk ${dstfname}${index}.png
#        vcmd="${vcmd} ${dstfname}${index}.png"
#    done

    convert $vcmd -append ${dstfname}00.png
    cd $rundir
}

convert-crop2(){
    #    WID=`xdotool search --name "^debian" | head -2`
    WID=`xdotool search --name "^debian.*Oracle" | head -2`
    ttt=`echo "$WID" | wc -l`
    if [[ $ttt != 1 ]];then
        echo "符合截图程序查询条件的实例数不为1，请修正查询条件后重试！==>$ttt"
        return
    fi

    echo "wid==>$WID"

    while (( 1 ));do
        echo "当前png文件个数为:`ls -al *.png | wc -l`"
        echo -n "回车开始截图:"
        read
        import -frame -window $WID tmp.png
        # convert tmp.png -crop 1020x512+2+178 `date '+%Y%m%d%H%M%S'`.png
        convert tmp.png -crop 1020x512+2+179 `date '+%Y%m%d%H%M%S'`.png
        #    import -frame -window $WID `date '+%Y%m%d%H%M%S'`.png
        clear
    done

}


convert-crop22(){
    dstfname='test'

    index=0
    vcmd=''
    for ppp in `ls 2018*.jpg|sort`;do
        index=$((index+1))

        if [[ $index == 1 ]];then
            cp ${ppp} ${dstfname}${index}.jpg
            vcmd="${vcmd} ${dstfname}${index}.jpg"
            continue;
        fi

        convert ${ppp} -crop 1020x55+0+457 ${dstfname}${index}.jpg
        vcmd="${vcmd} ${dstfname}${index}.jpg"
    done
    convert $vcmd -append ${dstfname}00.jpg
}

convert-crop3(){
    srcdir='/media/win/E/chuanqing/gitspace/debian-conf/'
    prefix='20181029'
    suffix='.png'
    dstfname='test'

    pp0='1024x512+0+178'
    pp1='1024x55+0+636'

    rundir=`pwd`

    cd "$srcdir"
    index=0
    vcmd=''

    for ppp in `ls|sort`;do
        index=$((index+1))

        kkk=$pp1
        if [[ $index == 1 ]];then
            kkk=$pp0
        fi

        convert ${ppp} -crop $kkk ${dstfname}${index}.png
        vcmd="${vcmd} ${dstfname}${index}.png"
    done

    convert $vcmd -append ${dstfname}00.png
    cd $rundir
}

$1
