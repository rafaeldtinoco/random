#!/bin/bash -x

# creates an iso image with a live os + curtin

if [[ $UID -ne 0 ]];
then
  sudo "$0" "$@" && exit 0 || exit 1
fi

# directories

scriptdir=$(dirname $0)

# includes

. ${scriptdir}/functions.sh
. ${scriptdir}/prereqs.sh
. ${scriptdir}/usage.sh

# prereqs

prereqs

# cleanup marks

clean_mount=0
clean_vfat=0

# arguments

hostname=""
cloudimg=""
distro=""
launchpad_id=""
username=""
repository=""
offlinepkgs=""

# usage

usage $@

# defaults (mandatory)

[[ "$hostname" == "" ]] && exiterr "something wrong is not right"

# defaults

[[ "$distro" == "" ]] && distro=$(ubuntu-distro-info --stable)
[[ "$launchpad_id" == "" ]] && launchpad_id="rafaeldtinoco"
[[ "$username" == "" ]] && username="ubuntu"
[[ "$repository" == "" ]] && repository="http://us.archive.ubuntu.com/ubuntu"
[[ "$cloudimg" == "" ]] && cloudimg="https://cloud-images.ubuntu.com/releases/bionic/release/ubuntu-18.04-server-cloudimg-amd64-root.tar.xz"

distro_devel=0
if [[ "$distro" == "groovy" ]];
then
  distro_devel=1
  distro="focal"
fi

# cleanup

cleanup() {
  [[ ${clean_mount} -eq 1 ]] && {
    echo "info: cleaning up mount leftovers"
    umount ${targetdir}/dev/pts >/dev/null 2>&1
    umount ${targetdir}/dev >/dev/null 2>&1
    umount ${targetdir}/sys >/dev/null 2>&1
    umount ${targetdir}/proc >/dev/null 2>&1
  }
}

trap cleanup EXIT

# environmetal

livebootdir="$scriptdir/../liveboot"
targetdir="$livebootdir/chroot"

cd ${livebootdir} ; livebootdir=$(pwd) ; cd - 2>&1 > /dev/null ;
cd ${targetdir}; targetdir=$(pwd) ; cd - 2>&1 > /dev/null ;

echo "info: targetdirt=$targetdir"
echo "info: livebootdir=$livebootdir"

checkdir ${livebootdir}
checkdir ${targetdir}

##
## debootstrap and chroot logic for the LIVE Ubuntu image
##

packages="vim jq  bash-completion net-tools openssh-client tcpdump "
packages+="iputils-arping iputils-ping iputils-tracepath traceroute mtr-tiny "
packages+="dnsutils ssh-import-id software-properties-common strace lsof"

echo "mark: debootstraping"

checknotdir ${targetdir}/boot

if [[ ! -f ${targetdir}/bin/bash ]];
then
  checkcond debootstrap \
    --components=main,restricted,universe,multiverse \
    --include="locales,sudo,less" \
    ${distro} \
    ${targetdir} \
    "$repository"
else
  echo "info: found previous debootstrap, checking version"
  targetversion=$(grep DISTRIB_CODENAME ${targetdir}/etc/lsb-release | cut -d'=' -f2)
  if [[ "$targetversion" != "$distro" ]];
  then
    exiterr "unsp: previous debootstrap has different distro version"
  fi
fi

echo "mark: mount {procfs,sysfs,devfs}"

checkcond mount -o bind /proc ${targetdir}/proc
checkcond mount -o bind /sys ${targetdir}/sys
checkcond mount -o bind /dev ${targetdir}/dev
checkcond mount -o bind /dev/pts ${targetdir}/dev/pts

clean_mount=1

echo "mark: setting hostname"

echo ${hostname} | teeshush "$targetdir/etc/hostname"

echo "mark: adjusting accounts"

runinjail "echo en_US.UTF-8 > /etc/locale.gen"
runinjail "locale-gen en_US.UTF-8"
runinjail "passwd -d root"

echo "mark: /etc/modules"

echo """## /etc/modules
ext4
## end of file""" | teeshush "$targetdir/etc/modules"

echo "mark: /etc/apt/sources.list"

[[ ${distro_devel} -eq 1 ]] && distro="groovy"

echo """## /etc/apt/sources.list
deb $repository $distro main restricted universe multiverse
deb $repository $distro-updates main restricted universe multiverse
deb $repository $distro-proposed main restricted universe multiverse
## end of file""" | teeshush "$targetdir/etc/apt/sources.list"

echo "mark: update and upgrade"

prefix="DEBIAN_FRONTEND=noninteractice"

runinjail "$prefix apt-get update"
runinjail "$prefix apt-get dist-upgrade -y"
runinjail "$prefix apt-get install -y $packages"
runinjail "$prefix apt-get install -y live-boot live-boot-initramfs-tools"
runinjail "$prefix apt-get install -y curtin"
runinjail "$prefix apt-get install -y linux-image-generic linux-headers-generic"
runinjail "$prefix apt-get install --no-install-recommends -y dpkg-dev"

runinjail "$prefix apt-get install --no-install-recommends -y lighttpd lynx"
runinjail "lighttpd-enable-mod dir-listing"
runinjail "rm -rf /var/www/html ; ln -s /curtin/repo /var/www/html"
runinjail "chown -R www-data:www-data /curtin/repo /var/www/html"

runinjail "$prefix apt-get --purge autoremove -y"
runinjail "$prefix apt-get autoclean"

cleanup ; clean_mount=0 ;

###
### main logic
###

[[ -d ${targetdir}/curtin ]] && rm -rf ${targetdir}/curtin

checkcond mkdir -p ${targetdir}/curtin/repo
checkdir ${targetdir}/curtin/repo
checkcond cp ${scriptdir}/files/* ${targetdir}/curtin/

checkdir ${scriptdir}/images
cloudimgfile=$(basename ${cloudimg})

if [[ ! -f ${scriptdir}/images/${cloudimgfile} ]];
then
  echo "info: downloading $cloudimgfile"
  checkcond wget ${cloudimg} -O ${scriptdir}/images/${cloudimgfile}
else
  echo "info: no need to download $cloudimgfile"
fi

checkfile ${scriptdir}/images/${cloudimgfile}
checkcond cp ${scriptdir}/images/${cloudimgfile} ${targetdir}/curtin/

echo "mark: configuring curtin and cloud-init yaml files"

repository=$(echo ${repository} | sed 's/\:/\\:/g' | sed 's/\./\\./g')

for yamlfile in ${targetdir}/curtin/*.yaml;
do
  sed -i "s:CHANGE_USERNAME:$username:g" ${yamlfile}
  sed -i "s:CHANGE_LAUNCHPAD_ID:$launchpad_id:g" ${yamlfile}
  sed -i "s:CHANGE_REPOSITORY:$repository:g" ${yamlfile}
  sed -i "s:CHANGE_CLOUD_IMG_FILE:$cloudimgfile:g" ${yamlfile}
done

#
# offline packages will be available to curtin installation
# through a 127.0.0.1 repo served by a lighttpd running out
# of the livecd instance
#

if [[ "$cloudimg" != *"$distro"* ]];
then
  exiterr "unsp: iso os version and install image must have same version"
fi

offlinepkgs+=",linux-image-generic,linux-headers-generic"
offlinepkgs+=",grub2,grub-efi,grub-efi-amd64"
offlinepkgs+=",grub-pc,grub-pc-bin"

echo "mark: configuring local (to live cdrom) repository"

echo """## /curtin/rdepends.sh
#!/bin/bash
REPO="/curtin/repo" ; cd \$REPO ;
for download in \$@; do
  apt download \$download \$(apt-cache depends \$download -i --recurse | tr -d '|,<,>, ' | sed -e 's/^Depends://g' | sed -e 's/^PreDepends://g' | sort -u | grep -v freefont | grep -v debconf-2.0 | xargs)
done
## end of file""" | teeshush "$targetdir/curtin/rdepends.sh"

checkfile ${targetdir}/curtin/rdepends.sh
runinjail "chmod +x /curtin/rdepends.sh"

for download in $(echo ${offlinepkgs} | sed 's:,: :g'); do
  runinjail "/curtin/rdepends.sh $download"
done

runinjail "cd /curtin/repo/ && dpkg-scanpackages . /dev/null | gzip -9c > ./Packages.gz"

##
## create the script responsible to call curtin install from livecd
##

echo """## /curtin/menu.sh
#!/bin/bash

cleanup() {
  halt
}
trap cleanup EXIT

mach=\$(whiptail --title \"Ubuntu Live Installer\" --radiolist \
       \"Select this machine type:\" 10 40 3 \
  1 \"Machine Type 01\" on \
  2 \"Machine Type 02\" off \
  3 \"Machine Type 03\" off 3>&1 1>&2 2>&3)

machtype=\"machine0\"\$mach

[ ! -f /curtin/\$machtype-curtin.yaml ] && { echo \"no curtin file\"; exit 1; }

curtin -v install -c /curtin/\$machtype-curtin.yaml

echo \"Press any key to halt ...\"
read
halt

## end of file""" | teeshush "$targetdir/curtin/menu.sh"

checkfile ${targetdir}/curtin/menu.sh
runinjail "chmod +x /curtin/menu.sh"

runinjail "mkdir -p /etc/systemd/system/getty@tty1.service.d"
runinjail "mkdir -p /etc/systemd/system/serial-getty@ttyS0.service.d"

echo """
[Service]
ExecStart=
ExecStart=-/bin/bash -c /curtin/menu.sh
StandardInput=tty
StandardOutput=tty
""" | teeshush "$targetdir/etc/systemd/system/getty@tty1.service.d/override.conf"

echo """
[Service]
ExecStart=
ExecStart=-/bin/bash -c /curtin/menu.sh
StandardInput=tty
StandardOutput=tty
""" | teeshush "$targetdir/etc/systemd/system/serial-getty@ttyS0.service.d/autologin.conf"

##
## Creating the LIVE OS squashfs image
##

echo "mark: creating squashfs"

checkfile /usr/lib/grub/i386-pc/cdboot.img
checkfile /usr/lib/grub/i386-pc/boot_hybrid.img

checkcond rm -f ${livebootdir}/image/live/filesystem.squashfs
checknotfile ${livebootdir}/image/live/filesystem.squashfs

mksquashfs \
  ${livebootdir}/chroot \
  ${livebootdir}/image/live/filesystem.squashfs \
  -e boot >> ${output} 2>&1

##
## Ubuntu LIVE ISO generation logic
##

checkfile ${livebootdir}/image/live/filesystem.squashfs

checkcond cp ${targetdir}/boot/vmlinuz-* ${livebootdir}/image/vmlinuz
checkcond cp ${targetdir}/boot/initrd.img-* ${livebootdir}/image/initrd

checkfile ${livebootdir}/image/vmlinuz
checkfile ${livebootdir}/image/initrd

echo "mark: creating grub.cfg"

cat <<EOF > ${livebootdir}/scratch/grub.cfg
search --set=root --file /UBUNTU_LIVE

insmod all_video

serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1
terminal_input serial
terminal_output serial

set default=0
set timeout=0

menuentry "UBUNTU" {
    linux /vmlinuz boot=live console=tty0 console=ttyS0,38400n8 apparmor=0 net.ifnames=0 elevator=noop nomodeset
    initrd /initrd
}
EOF

checkfile ${livebootdir}/scratch/grub.cfg

echo "mark: creating UBUNTU_LIVE file"

touch ${livebootdir}/image/UBUNTU_LIVE
checkfile ${livebootdir}/image/UBUNTU_LIVE

echo "mark: configuring EFI cdrom portion"

grub-mkstandalone \
  --format=x86_64-efi \
  --output=${livebootdir}/scratch/bootx64.efi \
  --locales="" \
  --fonts="" \
  "boot/grub/grub.cfg=$livebootdir/scratch/grub.cfg" >> ${output} 2>&1

(cd ${livebootdir}/scratch && \
  dd if=/dev/zero of=efiboot.img bs=1M count=10 && \
  mkfs.vfat efiboot.img && \
  mmd -i efiboot.img efi efi/boot && \
  mcopy -i efiboot.img ./bootx64.efi ::efi/boot/) >> ${output} 2>&1

checkfile ${livebootdir}/scratch/efiboot.img

echo "mark: configuring MBR cdrom portion"

grub-mkstandalone \
  --format=i386-pc \
  --output=${livebootdir}/scratch/core.img \
  --install-modules="linux normal iso9660 biosdisk memdisk search tar ls serial" \
  --modules="linux normal iso9660 biosdisk search serial" \
  --locales="" \
  --fonts="" \
  "boot/grub/grub.cfg=$livebootdir/scratch/grub.cfg" >> ${output} 2>&1

checkfile ${livebootdir}/scratch/core.img

cat \
  /usr/lib/grub/i386-pc/cdboot.img \
  ${livebootdir}/scratch/core.img \
> ${livebootdir}/scratch/bios.img

checkfile ${livebootdir}/scratch/bios.img

echo "mark: creating the ISO"

xorriso \
  -for_backup \
  -as mkisofs \
  -iso-level 3 \
  -full-iso9660-filenames \
  -volid "UBUNTU_LIVE" \
  -eltorito-boot \
    boot/grub/bios.img \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    --eltorito-catalog boot/grub/boot.cat \
  --grub2-boot-info \
  --grub2-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
  -eltorito-alt-boot \
    -e EFI/efiboot.img \
    -no-emul-boot \
  -append_partition 2 0xef ${livebootdir}/scratch/efiboot.img \
  -output "${livebootdir}/ubuntu-livecd.iso" \
  -graft-points \
    "${livebootdir}/image" \
    /boot/grub/bios.img=${livebootdir}/scratch/bios.img \
    /EFI/efiboot.img=${livebootdir}/scratch/efiboot.img >> ${output} 2>&1

checkfile ${livebootdir}/ubuntu-livecd.iso

echo "finished: your ISO can be found at $livebootdir/ubuntu-livecd.iso"

exit 0
