#!/bin/bash

#
# syntax: ./kvm.sh [options]
#
# options:
#         -c <#.cpus>             - number of cpus
#         -m <mem.GB>             - memory size
#         -n <vm.name>            - virtual machine name
#         -t <cloudinit>          - default/devel (check cloud-init/*.yaml files)
#         -i <libvirt>            - vanilla/numa/... (check libvirt/*.xmlfiles)
#         -d <ubuntu.codename>    - xenial/bionic/disco/eoan/focal (default: stable)
#         -u <username>           - as 1000:1000 in the installed vm (default: ubuntu)
#         -l <launchpad_id>       - for the ssh key import (default: rafaeldtinoco)
#         -p <proxy>              - proxy for http/https/ftp
#         -r <repo.url>           - url for the ubuntu mirror (default: us.archive)
#         -w                      - wait until cloud-init is finished (after 1st boot)
#

if [ $UID -ne 0 ]; then
  sudo --preserve-env=http_proxy "$0" "$@" && exit 0 || exit 1
fi

scriptdir=$(dirname $0)
ubuver=$(ubuntu-distro-info --stable)

. $scriptdir/../kvm/functions.sh
. $scriptdir/../kvm/prereqs.sh

prereqs

pooldir=$(virsh pool-dumpxml default | grep path | sed -E 's:</?path>::g; s:\s+::g')

virsh destroy testme > /dev/null 2>&1 ; sleep 1

virsh list --all --name | grep -q testme && {
  virsh undefine --remove-all-storage testme > /dev/null 2>&1
}

checknotdir "$pooldir/testme"

options="-w -c 4 -m 4 -n testme -t default -d $ubuver -u rafaeldtinoco -p $http_proxy"

for file in $scriptdir/../kvm/libvirt/*.xml
do

  file=$(basename $file)
  file=${file/\.xml/}

  echo "Do you want to run test with the vm $file ?"

  select yn in "Yes" "No"; do
    case $yn in
      Yes)
        $scriptdir/../kvm/kvm.sh $options "-i $file"
        break
        ;;
      No)
        break
        ;;
    esac
  done
done
