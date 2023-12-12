#!/bin/bash

# This script is meant for development purposes only!
#
# It generates a QEMU (KVM) machine that will work as if it was the main
# riband installer, to a second disk, available in this same machine,
# and that can be booted in a second virtual machine, testing the "just
# deployed" OS.
#
# Idea behind is that one can customize curtin and cloud-init
# configuration files by deploying from this practice vm initally.

if [ $UID -ne 0 ]; then
  sudo "$0" "$@" && exit 0 || exit 1
fi

prereqs() {

  command -v virsh > /dev/null 2>&1 || {
    echo "error: package libvirt-clients is not installed"
    exit 1
  }

  command -v ubuntu-distro-info > /dev/null 2>&1 || {
    echo "error: package distro-info is not installed"
    exit 1
  }

  command -v losetup > /dev/null 2>&1 || {
    echo "error: package mount is not installed"
    exit 1
  }

  command -v mkfs.ext4 > /dev/null 2>&1 || {
    echo "error: package e2fsprogs not installed"
    exit 1
  }

  command -v uuidgen > /dev/null 2>&1 || {
    echo "error: package uuid-runtime not installed"
    exit 1
  }

  command -v qemu-system-x86_64 > /dev/null 2>&1 || {
    echo "error: you're missing qemu installation"
    exit 1
  }

  command -v qemu-img > /dev/null 2>&1 || {
    echo "error: package qemu-utils not installed"
    exit 1
  }

  virsh net-info default > /dev/null 2>&1  || {
    echo "error: libvirt is missing network named \"default\""
    exit 1
  }

  virsh pool-info default > /dev/null 2>&1 || {
    echo "error: libvirt is missing storage pool named \"default\""
    exit 1
  }

  virsh pool-dumpxml default > /dev/null 2>&1 || {
    echo "error: libvirt could not dump default storage pool xml"
    exit
  }
}

prereqs

clean_truncate=0
clean_qcow2=0
clean_losetup=0
clean_mount=0
clean_rootdir=0

scriptdir=$(dirname $0); olddir=$(pwd);
[ "$scriptdir" == "." ] && scriptdir=$olddir
tmpdir="/tmp" ; cd /tmp

URL="http://br.archive.ubuntu.com/ubuntu"
launchpad_id="rafaeldtinoco"

export http_proxy="http://192.168.100.252:3128/"
export https_proxy="http://192.168.100.252:3128/"
export ftp_proxy="http://192.168.100.252:3128/"

hostname="testme"           # installed OS and VM name
vcpus=2                     # default: 2 vcpus for both VMs (riband and testme)
ramgb=2                     # default: 2 GB ram for both VMs (riband and testme)
#network                    # libvirt network: "default"
#pool                       # libvirt storage pool: "default"
#distro                     # default: latest ubuntu-lts
target=$(mktemp -d XXXXXX)  # temporary debootstrap dir

targetdir="$tmpdir/$target"

[ -d "$targetdir" ] || {
    echo "error: $targetdir should exist by now, exiting"
    exit 1
}

distro=$(ubuntu-distro-info --lts)
network=$(virsh net-info default | grep Bridge | awk '{print $2}')
pooldir=$(virsh pool-dumpxml default | grep path | sed -E 's:</?path>::g; s:\s+::g')
qemubin=$(which qemu-system-x86_64)
newmac=$(printf '52:54:00:%02X:%02X:%02X\n' $[RANDOM%256] $[RANDOM%256] $[RANDOM%256])

loopavail=$(losetup -f)           # loop device to use for debootstrapping
rootdir="$pooldir/$hostname"      # installer libvirt "default" pool directory
rootfs="$rootdir/disk01.ext4"     # installer root disk
rootsize=10G                      # installer root disk size
qcow2vol="$rootdir/disk02.qcow2"  # to-be-installed disk (by curtin)
qcow2size=30G                     # to-be-installed disk size

mkdir "$rootdir" && clean_rootdir=1 || {
  echo "error: could not create $rootdir"
  exit 1
}

# extra packages to install during debootstrap phase

packages=""
packages+="locales,"
packages+="less,"
packages+="vim,"
packages+="sudo,"
packages+="openssh-server,"
packages+="openssh-client,"
packages+="bash-completion,"
packages+="wget,"
packages+="rsync,"
packages+="iputils-ping,"
packages+="tcpdump,"
packages+="dnsutils,"
packages+="curl,"
packages+="ifupdown,"
packages+="bridge-utils,"
packages+="net-tools,"
packages+="vlan,"
packages+="lsb-release"

# cleanup loopback device and mounted dirs when exiting

cleanup() {
  echo "finish: cleaning up leftovers"

  [ $clean_mount -eq 1 ] && {
    umount $targetdir/dev/pts > /dev/null 2>&1
    umount $targetdir/dev > /dev/null 2>&1
    umount $targetdir/sys > /dev/null 2>&1
    umount $targetdir/proc > /dev/null 2>&1
    umount $targetdir
  }
  [ $clean_losetup -eq 1 ] && losetup -d $loopavail
  [ $clean_truncate -eq 1 ] && rm $rootfs
  [ $clean_qcow2 -eq 1 ] && rm $qcow2vol
  [ $clean_rootdir -eq 1 ] && rmdir $rootdir

  rm -f $tmpdir/riband.xml
  rm -f $tmpdir/$hostname.xml
}

trap cleanup EXIT

# some initial prereqs

truncate "$rootfs" -s "$rootsize" > /dev/null 2>&1 && clean_truncate=1 || {
  echo "error: could not truncate $rootfs to $rootsize"
  exit 1
}

qemu-img create -f qcow2 $qcow2vol $qcow2size > /dev/null 2>&1 && clean_qcow2=1 || {
  echo "error: could not create qcow2 volume $qcow2vol"
  exit 1
}

mkfs.ext4 -LROOTFS "$rootfs" > /dev/null 2>&1 || {
  echo "error: could not create ext4 filesystem"
  exit 1
}

losetup "$loopavail" "$rootfs" > /dev/null 2>&1 && clean_losetup=1 || {
  echo "error: could not map $loopavail loop device"
  exit 1
}

mount_opts="noatime,nodiratime,relatime,discard,errors=remount-ro"

mount -o $mount_opts "$rootfs" "$targetdir" > /dev/null 2>&1 && clean_mount=1 || {
  echo "error: could not mount $rootfs into $targetdir"
  exit 1
}

# we have loopback device mounted at "$targetdir" now

# start debootstrap

debootstrap --include="$packages" "$distro" "$targetdir" "$URL" || {
  echo "error: debootstraping $distro into $targetdir failed"
  exit 1
}

# mount {procfs,sysfs,devfs}

mount -o bind /proc $targetdir/proc
mount -o bind /sys $targetdir/sys
mount -o bind /dev $targetdir/dev
mount -o bind /dev/pts $targetdir/dev/pts

# set installer hostname

echo riband | tee $targetdir/etc/hostname

# adjust accounts

chroot $targetdir /bin/bash -c "echo en_US.UTF-8 > /etc/locale.gen"
chroot $targetdir /bin/bash -c "locale-gen en_US.UTF-8"

chroot $targetdir /bin/bash -c "groupadd -g 1000 ubuntu"
chroot $targetdir /bin/bash -c "useradd -s /bin/bash -g 1000 -u 1000 -m ubuntu"

chroot $targetdir /bin/bash -c "passwd -d root"
chroot $targetdir /bin/bash -c "passwd -d ubuntu"

chroot $targetdir /bin/bash -c "usermod -a -G root ubuntu"
chroot $targetdir /bin/bash -c "usermod -a -G sys ubuntu"
chroot $targetdir /bin/bash -c "usermod -a -G sudo ubuntu"
chroot $targetdir /bin/bash -c "usermod -a -G staff ubuntu"
chroot $targetdir /bin/bash -c "usermod -a -G users ubuntu"
chroot $targetdir /bin/bash -c "usermod -a -G nogroup ubuntu"

# /etc/apt/apt.conf

echo """## /etc/apt/apt.conf

Acquire::http::Proxy \"$http_proxy\";

Dpkg::Options {
   \"--force-confdef\";
   \"--force-confold\";
}

## end of file""" | tee $targetdir/etc/apt/apt.conf

# /etc/sudoers

echo """## /etc/sudoers

Defaults env_keep += \"LANG LANGUAGE LINGUAS LC_* _XKB_CHARSET\"
Defaults env_keep += \"HOME EDITOR SYSTEMD_EDITOR PAGER\"

Defaults secure_path=\"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\"

Defaults logfile=/var/log/sudo.log,loglinelen=0
Defaults !syslog, !pam_session

root ALL=(ALL) NOPASSWD: ALL
%wheel ALL=(ALL) NOPASSWD: ALL
%sudo ALL=(ALL) NOPASSWD: ALL
ubuntu ALL=(ALL) NOPASSWD: ALL

## end of file""" | tee $targetdir/etc/sudoers

# /etc/fstab

echo """## /etc/fstab

/dev/vda / ext4 noatime,nodiratime,relatime,discard,errors=remount-ro 0 1

## end of file""" | tee $targetdir/etc/fstab

# /etc/modules and /etc/initramfs-tools/modules

echo """## /etc/modules
virtio_balloon
virtio_blk
virtio_net
virtio_pci
virtio_ring
virtio
ext4
## end of file""" | tee $targetdir/etc/modules

echo """## /etc/initramfs-tools/modules
virtio_balloon
virtio_blk
virtio_net
virtio_pci
virtio_ring
virtio
ext4
## end of file""" | tee $targetdir/etc/initramfs-tools/modules

# /etc/apt/sources.list

echo """## /etc/apt/sources.list

deb $URL $distro main restricted universe multiverse
deb $URL $distro-updates main restricted universe multiverse
deb $URL $distro-proposed main restricted universe multiverse
# deb $URL $distro-backports main restricted universe multiverse
# deb http://security.ubuntu.com/ubuntu $distro-security main restricted universe multiverse

deb-src $URL $distro main restricted universe multiverse
deb-src $URL $distro-updates main restricted universe multiverse
deb-src $URL $distro-proposed main restricted universe multiverse
# deb-src $URL $distro-backports main restricted universe multiverse
# deb-src http://security.ubuntu.com/ubuntu $distro-security main restricted universe multiverse

# deb http://ddebs.ubuntu.com $distro main restricted universe multiverse
# deb http://ddebs.ubuntu.com $distro-updates main restricted universe multiverse
# deb http://ddebs.ubuntu.com $distro-proposed main restricted universe multiverse

## end of file""" | tee $target/etc/apt/sources.list

chroot $targetdir /bin/bash -c "http_proxy=\'$http_proxy\' apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 04EE7237B7D453EC"
chroot $targetdir /bin/bash -c "http_proxy=\'$http_proxy\' apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 7638D0442B90D010"
chroot $targetdir /bin/bash -c "http_proxy=\'$http_proxy\' apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C8CAB6595FDFF622"

# /etc/{motd,issue,issue.net}

echo "" | tee $targetdir/etc/motd
echo "" | tee $targetdir/etc/issue
echo "" | tee $targetdir/etc/issue.net

# /etc/ssh/{sshd_config,ssh_config}

echo """## /etc/ssh/sshd_config

Port 22
AddressFamily any
SyslogFacility AUTH
LogLevel INFO
PermitRootLogin yes
PubkeyAuthentication yes
PasswordAuthentication yes
ChallengeResponseAuthentication no
GSSAPIAuthentication no
HostbasedAuthentication no
PermitEmptyPasswords no
UsePAM yes
IgnoreUserKnownHosts yes
IgnoreRhosts yes
X11Forwarding yes
X11DisplayOffset 10
X11UseLocalhost yes
PermitTTY yes
PrintMotd no
TCPKeepAlive yes
PermitTunnel yes
Banner none
AcceptEnv LANG LC_* EDITOR PAGER SYSTEMD_EDITOR
Subsystem	sftp	/usr/lib/openssh/sftp-server

## end of file""" | tee $targetdir/etc/ssh/sshd_config

echo """## /etc/ssh/ssh_config

Host *
  ForwardAgent no
  ForwardX11 no
  PasswordAuthentication yes
  CheckHostIP no
  AddressFamily any
  SendEnv LANG LC_* EDITOR PAGER
  StrictHostKeyChecking no
  HashKnownHosts yes

## end of file""" | tee $targetdir/etc/ssh/ssh_config

# /etc/hosts

echo """## /etc/hosts

127.0.0.1 localhost
127.0.1.1 $hostname

::1 localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters

## end of file""" | tee $targetdir/etc/hosts

# /etc/network/interfaces

echo """## /etc/network/interfaces

auto lo
iface lo inet loopback
    post-up sysctl -w net.ipv4.conf.all.forwarding=0
    post-up sysctl -w net.ipv4.conf.default.forwarding=0

auto eth0
iface eth0 inet dhcp
    post-up sysctl -w net.ipv4.conf.eth0.forwarding=0

## end of file""" | tee $targetdir/etc/network/interfaces

# upgrade

chroot $targetdir /bin/bash -c "apt-get update ; DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y"
chroot $targetdir /bin/bash -c "DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y linux-image-generic linux-headers-generic"
chroot $targetdir /bin/bash -c "DEBIAN_FRONTEND=noninteractive apt-get install -y ssh-import-id"
chroot $targetdir /bin/bash -c "DEBIAN_FRONTEND=noninteractive apt-get install -y software-properties-common"
chroot $targetdir /bin/bash -c "DEBIAN_FRONTEND=noninteractive apt-get install -y curtin lshw"
chroot $targetdir /bin/bash -c "DEBIAN_FRONTEND=noninteractive apt-get install -y cloud-init"
chroot $targetdir /bin/bash -c "DEBIAN_FRONTEND=noninteractive apt-get --purge autoremove -y"
chroot $targetdir /bin/bash -c "DEBIAN_FRONTEND=noninteractive apt-get autoclean"

# install curtin

# create the virtual machine xml file

uuid1=$(uuidgen)
uuid2=$(uuidgen)

# shellcheck disable=SC2089
ribandxml="""
<domain type='kvm'>
  <name>riband</name>
  <uuid>$uuid1</uuid>
  <memory unit='GiB'>$ramgb</memory>
  <currentMemory unit='GiB'>$ramgb</currentMemory>
  <vcpu placement='static'>$vcpus</vcpu>
  <resource>
    <partition>/machine</partition>
  </resource>
  <!-- -->
  <os>
    <type arch='x86_64' machine='pc'>hvm</type>
    <kernel>$rootdir/vmlinuz</kernel>
    <initrd>$rootdir/initrd.img</initrd>
    <cmdline>root=/dev/vda noresume console=tty0 console=ttyS0,38400n8 apparmor=0 net.ifnames=0 cloud-init=disabled</cmdline>
    <boot dev='hd'/>
  </os>
  <features>
    <acpi/>
    <apic/>
  </features>
  <cpu mode='host-passthrough' check='none'/>
  <!-- -->
  <clock offset='utc'>
    <timer name='rtc' tickpolicy='catchup'/>
    <timer name='pit' tickpolicy='delay'/>
    <timer name='hpet' present='yes'/>
  </clock>
  <!-- -->
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>restart</on_crash>
  <pm>
    <suspend-to-mem enabled='no'/>
    <suspend-to-disk enabled='no'/>
  </pm>
  <!-- -->
  <devices>
    <!-- -->
    <emulator>$qemubin</emulator>
    <input type='mouse' bus='ps2'/>
    <input type='keyboard' bus='ps2'/>
    <!-- -->
    <controller type='usb' index='0' model='piix3-uhci'/>
    <controller type='pci' index='0' model='pci-root'/>
    <!-- -->
    <memballoon model='virtio'/>
    <!-- -->
    <disk type='file' device='disk'>
      <driver name='qemu' type='raw'/>
      <source file='$rootdir/disk01.ext4'/>
      <target dev='vda' bus='virtio'/>
    </disk>
    <!-- -->
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='$rootdir/disk02.qcow2'/>
      <target dev='vdb' bus='virtio'/>
    </disk>
    <interface type='network'>
      <source network='default'/>
      <model type='virtio'/>
    </interface>
    <!-- -->
    <serial type='pty'>
      <target type='isa-serial' port='0'>
        <model name='isa-serial'/>
      </target>
    </serial>
    <console type='pty'>
      <target type='serial' port='0'/>
    </console>
    <!-- -->
  </devices>
</domain>
"""

# shellcheck disable=SC2089
vmxml="""
<domain type='kvm'>
  <name>$hostname</name>
  <uuid>$uuid2</uuid>
  <memory unit='GiB'>$ramgb</memory>
  <currentMemory unit='GiB'>$ramgb</currentMemory>
  <vcpu placement='static'>$vcpus</vcpu>
  <resource>
    <partition>/machine</partition>
  </resource>
  <!-- -->
  <os>
    <type arch='x86_64' machine='pc'>hvm</type>
    <boot dev='hd'/>
  </os>
  <features>
    <acpi/>
    <apic/>
  </features>
  <cpu mode='host-passthrough' check='none'/>
  <!-- -->
  <clock offset='utc'>
    <timer name='rtc' tickpolicy='catchup'/>
    <timer name='pit' tickpolicy='delay'/>
    <timer name='hpet' present='yes'/>
  </clock>
  <!-- -->
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>restart</on_crash>
  <pm>
    <suspend-to-mem enabled='no'/>
    <suspend-to-disk enabled='no'/>
  </pm>
  <!-- -->
  <devices>
    <!-- -->
    <emulator>$qemubin</emulator>
    <input type='mouse' bus='ps2'/>
    <input type='keyboard' bus='ps2'/>
    <!-- -->
    <controller type='usb' index='0' model='piix3-uhci'/>
    <controller type='pci' index='0' model='pci-root'/>
    <!-- -->
    <memballoon model='virtio'/>
    <!-- -->
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='$rootdir/disk02.qcow2'/>
      <target dev='vda' bus='virtio'/>
    </disk>
    <interface type='network'>
      <source network='default'/>
      <model type='virtio'/>
    </interface>
    <!-- -->
    <serial type='pty'>
      <target type='isa-serial' port='0'>
        <model name='isa-serial'/>
      </target>
    </serial>
    <console type='pty'>
      <target type='serial' port='0'/>
    </console>
    <!-- -->
  </devices>
</domain>
"""

# create the qemu virtual machine using generated xml

echo $ribandxml > $tmpdir/riband.xml
echo $vmxml > $tmpdir/$hostname.xml

virsh define $tmpdir/riband.xml > /dev/null 2>&1 || {
  echo "error: virsh could not define riband.xml"
  exit 1
}

virsh define $tmpdir/$hostname.xml > /dev/null 2>&1 || {
  echo "error: virsh could not define $hostname.xml"
  exit 1
}

rm $tmpdir/riband.xml
rm $tmpdir/$hostname.xml

# transfer kernel and initrd to host for riband vm

fvmlinuz=$(ls -t1 $targetdir/boot/vmlinuz*generic | tail -1)

cp $fvmlinuz $rootdir/vmlinuz || {
  echo "error: could not get vmlinuz file $fvmlinuz from vm!"
  exit 1
}

finitrd=$(ls -t1 $targetdir/boot/initrd*generic | tail -1)

cp $finitrd $rootdir/initrd.img || {
  echo "error: could not get initrd file $initrd from vm!"
  exit 1
}

# import given key to ubuntu user home directory

chroot $targetdir /bin/bash -c "su - ubuntu -c \"ssh-import-id $launchpad_id\""

# copy curtin.yaml and user-data.yaml into generated virtual machine

cp $scriptdir/curtin.yaml $targetdir/home/ubuntu/ > /dev/null 2>&1 || \
  echo "warning: could not copy curtin.yaml to vm!"

cp $scriptdir/user-data.yaml $targetdir/home/ubuntu/ > /dev/null 2>&1 || \
  echo "warning: could not copy user-data.yaml to vm!"

# clean things up

clean_mount=1
clean_losetup=1
clean_truncate=0
clean_qcow2=0
clean_rootdir=0

cd $olddir

exit 0


}
