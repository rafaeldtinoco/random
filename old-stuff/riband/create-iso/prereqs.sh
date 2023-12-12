#!/bin/bash

proxy=""

# when regular ./iso.sh is executed

isoprereqs() {
  checkreq debootstrap debootstrap
  checkreq mksquashfs squashfs-tools
  checkpkg grub-pc-bin
  checkpkg grub-efi-amd64
  checkpkg mtools
  checkpkg xorriso
  checkpkg wget
}

# when ./fixenv.sh is executed

isoprereqsinst() {
  checkreqinst debootstrap debootstrap
  checkreqinst mksquashfs squashfs-tools
  checkpkginst grub-pc-bin
  checkpkginst grub-efi-amd64
  checkpkginst mtools
  checkpkginst xorriso
  checkpkginst wget
}

# prereqs fucntion

prereqs() {

  # proxy

  if [[ "$proxy" != "" ]]; then
    export http_proxy=${proxy}
    export https_proxy=${proxy}
    export ftp_proxy=${proxy}
  fi

  output="/tmp/iso.log"
  echo > ${output}
  echo "info: logs at $output"

  [[ "$0" =~ iso.sh ]] && isoprereqs
  [[ "$0" =~ fixenv.sh ]] && isoprereqs
}