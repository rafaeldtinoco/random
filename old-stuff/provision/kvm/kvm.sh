#!/bin/bash

# bootstraps a qcow2 image using debootstrap
# feeds user-data cloud-init yaml file into it

if [ $UID -ne 0 ];
then
  sudo --preserve-env=http_proxy "$0" "$@" && exit 0 || exit 1
fi

# directories

scriptdir=$(dirname $0)

# includes

. $scriptdir/functions.sh
. $scriptdir/prereqs.sh
. $scriptdir/usage.sh

# prereqs

prereqs

# cleanup marks

clean_nbd=0
clean_qcow2=0
clean_mount=0
clean_vfat=0

# arguments

vcpus=""
ramgb=""
hostname=""
cloudinit=""
username=""
launchpad_id=""
proxy=""
wait=0
cdromvol=""
noinstall=0
noqcow2create=0

usage $@

# defaults (mandatory)

[ "$hostname" == "" ] && exiterr "something wrong is not right"
[ "$vcpus" == "" ] && exiterr "something wrong is not right"
[ "$ramgb" == "" ] && exiterror "something wrong is not right"

# defaults

[ "$cloudinit" == "" ] && cloudinit="default"
[ "$distro" == "" ] && distro=$(ubuntu-distro-info --stable)
[ "$launchpad_id" == "" ] && launchpad_id="rafaeldtinoco"
[ "$username" == "" ] && username="ubuntu"
[ "$repository" == "" ] && repository="http://br.archive.ubuntu.com/ubuntu"

[ "$proxy" != "" ] && export HTTP_PROXY="$proxy" ; export http_proxy=$proxy
[ "$proxy" != "" ] && export HTTPS_PROXY="$proxy" ; export https_proxy=$proxy
[ "$proxy" != "" ] && export FTP_PROXY="$proxy" ; export ftp_proxy=$proxy


distro_devel=0
if [ "$distro" == "groovy" ];
then
  distro_devel=1
  distro="focal"
fi

# environmetal

network=$(virsh net-info default | grep Bridge | awk '{print $2}')
pooldir=$(virsh pool-dumpxml default | grep path | sed -E 's:</?path>::g; s:\s+::g')
qemubin=$(which qemu-system-x86_64)
newmac=$(printf '52:54:00:%02X:%02X:%02X\n' $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)))

do_tempdirs() {

  # temp dirs

  cd /tmp

  target=$(mktemp -d XXXXXX)   # temporary debootstrap dir
  fattarget=$(mktemp -d XXXXX) # temporary user-data mount dir

  cd - >/dev/null 2>&1

  targetdir="/tmp/$target"
  checkdir $targetdir

  fattargetdir="/tmp/$fattarget"
  checkdir $fattargetdir

  # find next available nbd device

  nbdfound=""
  for nbdavail in /dev/nbd*; do
    lsblk | grep -q "$nbdavail " || {
      nbdfound=$nbdavail
      break
    }
  done

}

[ $noinstall -eq 0 ] && do_tempdirs

do_checkqcow2() {

  # check qcow2 existence

  qcow2vol="$pooldir/$hostname-disk01.qcow2"
  qcow2size=30G
  checknotfile $qcow2vol
}


[ $noqcow2create -eq 0 ] && do_checkqcow2

cleanup() {

  # cleanup loopback device and mounted dirs when exiting

  echo "finish: cleaning up leftovers"

  if [ $noinstall -eq 0 ];
  then
    [ $clean_vfat -eq 1 ] && umount $fattargetdir >/dev/null 2>&1
    [ $clean_mount -eq 1 ] && {
      umount $targetdir/dev/pts >/dev/null 2>&1
      umount $targetdir/dev >/dev/null 2>&1
      umount $targetdir/sys >/dev/null 2>&1
      umount $targetdir/proc >/dev/null 2>&1
      umount $targetdir
    }
  fi

  if [ $clean_nbd -eq 1 ];
  then
    qemu-nbd -d $nbdfound >/dev/null 2>&1
  fi

  sync ; sync ; sync

  if [ $clean_qcow2 -eq 1 ];
  then
    virsh vol-delete --pool default $(basename $qcow2vol) >/dev/null 2>&1
  fi

  # rm -f /tmp/vm$$.xml

  if [ $noinstall -eq 0 ];
  then
    rmdir $targetdir
    rmdir $fattargetdir
  fi

  if [ $wait -ne 0 ];
  then
    echo "mark: waiting cloud-init to complete"
    checkcond virsh start $hostname
    waitvm
  fi
}

trap cleanup EXIT

do_qcow2creation() {

  echo "mark: qcow2 image"

  checkcond virsh vol-create-as default $(basename $qcow2vol) $qcow2size --format qcow2
  clean_qcow2=1

  sync ; sync ; sync
}

[ $noqcow2create -eq 0 ] && do_qcow2creation

do_initialprereqs() {

  [ "$nbdfound" == "" ] && exiterr "error: could not find an available nbd device"

  echo "mark: nbd connecting qcow2 image"

  checkcond qemu-nbd -n -c $nbdavail $qcow2vol
  clean_nbd=1

  echo "mark: disk formatting"

  printf "n\n\n\n+10MB\n\nn\n\n\n\n\nw\ny\n" | gdisk $nbdavail >/dev/null 2>&1

  sync ; sync ; sync

  echo "mark: vfat partition"

  checkcond mkfs.vfat -nCIDATA ${nbdavail}p1
  checkcond mount -t vfat ${nbdavail}p1 $fattargetdir
  clean_vfat=1

  echo "mark: ext4 partition"

  mount_opts="noatime,nodiratime,relatime,discard,errors=remount-ro"
  checkcond mkfs.ext4 -LMYROOT ${nbdavail}p2
  checkcond mount -o $mount_opts ${nbdavail}p2 $targetdir
  clean_mount=1

}

[ $noinstall -eq 0 ] && do_initialprereqs

do_debootstrap() {

  # extra packages to install during debootstrap phase

  packages="locales,ifupdown"

  # start debootstrap

  echo "mark: debootstraping (proxy: $http_proxy)"

  checkcond debootstrap \
    --components=main,restricted,universe,multiverse \
    --include="$packages" \
    $distro \
    $targetdir \
    "$repository"

  echo "mark: mount {procfs,sysfs,devfs}"

  checkcond mount -o bind /proc $targetdir/proc
  checkcond mount -o bind /sys $targetdir/sys
  checkcond mount -o bind /dev $targetdir/dev
  checkcond mount -o bind /dev/pts $targetdir/dev/pts

  echo "mark: setting hostname"

  echo $hostname | teeshush "$targetdir/etc/hostname"

  echo "mark: adjusting accounts"

  runinjail "echo en_US.UTF-8 > /etc/locale.gen"
  runinjail "locale-gen en_US.UTF-8"
  runinjail "passwd -d root"

  echo "mark: /etc/fstab"

  echo """LABEL=MYROOT / ext4 noatime,nodiratime,relatime,discard,errors=remount-ro 0 1

10.250.99.1:/home /home nfs vers=3,rw,sync,rdirplus,proto=udp,nolock,hard,noac,rsize=65536,wsize=65536,timeo=30 0 0
10.250.99.1:/root /root nfs vers=3,rw,sync,rdirplus,proto=udp,nolock,hard,noac,rsize=65536,wsize=65536,timeo=30 0 0

""" | teeshush "$targetdir/etc/fstab"

  echo "mark: /etc/network/interfaces"

  echo """auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
""" | teeshush "$targetdir/etc/network/interfaces"

  echo "mark: /etc/modules"

  echo """virtio_balloon
virtio_blk
virtio_net
virtio_pci
virtio_ring
virtio
ext4
""" | teeshush "$targetdir/etc/modules"

  echo "mark: /etc/default/grub"

  echo """GRUB_DEFAULT=0
GRUB_HIDDEN_TIMEOUT_QUIET=true
GRUB_TIMEOUT=2
GRUB_DISTRIBUTOR=$(lsb_release -i -s 2>/dev/null || echo Debian)
GRUB_CMDLINE_LINUX_DEFAULT="\"root=/dev/vda2 console=tty0 console=hvc0 apparmor=0 net.ifnames=0 elevator=noop nomodeset\""
GRUB_CMDLINE_LINUX=\"\"
GRUB_TERMINAL=serial
GRUB_SERIAL_COMMAND=\"serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1\"
GRUB_DISABLE_LINUX_UUID=\"true\"
GRUB_DISABLE_RECOVERY=\"true\"
GRUB_DISABLE_OS_PROBER=\"true\"""" | teeshush "$targetdir/etc/default/grub"

  echo "mark: /etc/apt/sources.list"

  [ $distro_devel -eq 1 ] && distro="groovy"

  echo """deb $repository $distro main restricted universe multiverse
deb $repository $distro-updates main restricted universe multiverse
deb $repository $distro-proposed main restricted universe multiverse""" | teeshush "$targetdir/etc/apt/sources.list"

  echo "mark: update and upgrade"

  prefix="DEBIAN_FRONTEND=noninteractice"

  runinjail "$prefix apt-get update"
  runinjail "$prefix apt-get dist-upgrade -y"
  runinjail "$prefix apt-get install -y cloud-init"
  runinjail "$prefix apt-get install -y grub2 linux-image-generic linux-headers-generic"
  runinjail "$prefix apt-get install -y nfs-common"
  runinjail "$prefix apt-get --purge autoremove -y"
  runinjail "$prefix apt-get autoclean"

  echo "mark: grub setup"

  runinjail "echo debconf debconf/priority select low | debconf-set-selections"
  runinjail "echo grub2 grub2/linux_cmdline_default string \"root=/dev/vda2 console=tty0 console=ttyS0,38400n8 apparmor=0 net.ifnames=0 elevator=noop pti=off kpti=off nopcid noibrs noibpb spectre_v2=off nospec_store_bypass_disable l1tf=off\" | debconf-set-selections"
  runinjail "echo grub2 grub2/linux_cmdline string | debconf-set-selections"
  runinjail "echo grub-pc grub-pc/install_devices string /dev/vda | debconf-set-selections"

  runinjail "$prefix dpkg-reconfigure debconf"
  runinjail "$prefix dpkg-reconfigure grub2"
  runinjail "$prefix dpkg-reconfigure grub-pc"

  runinjail "grub-install --force ${nbdavail}"
  runinjail "update-grub"

}

[ $noinstall -eq 0 ] && do_debootstrap

echo "mark: creating vm"

uuid=$(uuidgen)

# vars
export uuid=$uuid
export hostname=$hostname
export ramgb=$ramgb
export vcpus=$vcpus
export qemubin=$qemubin

# conditional vars (to fail on purpose if something wrong)
[ "$cdromvol" != "" ]  && export cdromvol=$cdromvol
[ $noqcow2create -eq 0 ] && export qcow2vol=$qcow2vol

# internal vars
export _vcpus_max=$_vcpus_max
export _vcpus_half_minus=$_vcpus_half_minus
export _vcpus_half=$_vcpus_half
export _ramgb_half=$_ramgb_half
export _ramgb_double=$_ramgb_double
export _ramgb_p2=$_ramgb_p2

cat $scriptdir/libvirt/$libvirt.xml | envsubst >/tmp/vm$$.xml

checkcond virsh define /tmp/vm$$.xml

echo "mark: meta-data and user-data"

if [ $noinstall -eq 0 ];
then
  checkcond cp $scriptdir/cloud-init/$cloudinit.yaml $fattargetdir/user-data
  checkcond echo "\"{instance-id: $uuid)}\"" | teeshush "$fattargetdir/meta-data"

  echo "mark: adjust user-data"

  proxy=$(echo $proxy | sed 's/\:/\\:/g' | sed 's/\./\\./g')
  repository=$(echo $repository | sed 's/\:/\\:/g' | sed 's/\./\\./g')

  sed -i "s:CHANGE_USERNAME:$username:g" $fattargetdir/user-data
  sed -i "s:CHANGE_LAUNCHPAD_ID:$launchpad_id:g" $fattargetdir/user-data
  sed -i "s:CHANGE_PROXY:$proxy:g" $fattargetdir/user-data
  sed -i "s:CHANGE_HTTP_PROXY:$proxy:g" $fattargetdir/user-data
  sed -i "s:CHANGE_HTTPS_PROXY:$proxy:g" $fattargetdir/user-data
  sed -i "s:CHANGE_FTP_PROXY:$proxy:g" $fattargetdir/user-data
  sed -i "s:CHANGE_REPOSITORY:$repository:g" $fattargetdir/user-data
fi

echo "mark: cleaning things up"

clean_mount=1
clean_vfat=1
clean_nbd=1
clean_qcow2=0

checkcond virsh start $hostname

exit 0
