#!/bin/bash

# check all prereqs for kvm script

kvmprereqs() {

  checkreq virsh libvirt-clients
  checkreq mkfs.ext4 e2fsprogs
  checkreq fdisk fdisk
  checkreq gdisk gdisk
  checkreq uuidgen uuid-runtime
  checkreq qemu-system-x86_64 qemu-system-x86
  checkreq qemu-img qemu-utils

  checkcond virsh net-info default
  checkcond virsh pool-info default
  checkcond virsh pool-dumpxml default

}

# install prereqs for kvm script

kvmprereqsinst() {

  checkreqinst virsh libvirt-clients
  checkreqinst mkfs.ext4 e2fsprogs
  checkreqinst fdisk fdisk
  checkreqinst gdisk gdisk
  checkreqinst uuidgen uuid-runtime
  checkreqinst qemu-system-x86_64 qemu-system-x86
  checkreqinst qemu-img qemu-utils

  # TODO: define default pool & network if not defined
}

# prereqs fucntion

prereqs() {

  # proxy

  if [ "$proxy" != "" ]; then
    export http_proxy=$proxy
    export https_proxy=$proxy
    export ftp_proxy=$proxy
  fi

  output="/tmp/kvm.log"
  echo > $output
  echo "info: logs at $output"

  [[ "$0" =~ kvm.sh ]] && kvmprereqs
  [[ "$0" =~ fixenv.sh ]] && kvmprereqsinst

}
