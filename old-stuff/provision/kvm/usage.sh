#!/bin/bash

# check all arguments given to kvm script

getoptkvm() {

  while getopts ":c:m:n:t:d:p:l:u:r:i:o:kqhw" opt; do
    case ${opt} in
    c)
      vcpus=$OPTARG
      _vcpus_max=$(($vcpus-1))
      _vcpus_half=$(($vcpus/2))
      _vcpus_half_minus=$((($vcpus/2)-1))
      echo "option: vcpus=$vcpus"
      ;;
    m)
      ramgb=$OPTARG
      _ramgb_half=$(($ramgb/2))
      _ramgb_double=$(($ramgb*2))
      _ramgb_p2=$(($ramgb+2))
      echo "option: ramgb=$ramgb"
      ;;
    n)
      hostname=$OPTARG
      echo "option: hostname=$hostname"
      ;;
    t)
      cloudinit=$OPTARG
      echo "option: cloudinit=cloud-init/$cloudinit.yaml"
      ;;
    d)
      distro=$OPTARG
      echo "option: distro=$distro"
      ;;
    p)
      # shellcheck disable=SC2034
      proxy=$OPTARG
      echo "option: proxy=$proxy"
      ;;
    l)
      launchpad_id=$OPTARG
      echo "option: launchpad_id=$launchpad_id"
      ;;
    u)
      username=$OPTARG
      echo "option: username=$username"
      ;;
    r)
      repository=$OPTARG
      echo "option: repository=$repository"
      ;;
    i)
      libvirt=$OPTARG
      echo "option: libvirt=libvirt/$libvirt.xml"
      ;;
    w)
      wait=1
      echo "option: wait vm"
      ;;
    o)
      cdromvol=$OPTARG
      echo "option: cdromvol=$cdromvol"
      ;;
    k)
      noinstall=1
      echo "option: noinstall"
      ;;
    q)
      noqcow2create=1
      echo "option: noqcow2create"
      ;;
    h)
      printf "\n"
      printf "syntax: $0 [options]\n"
      printf "\n"
      printf "options:\n"
      printf "\t-c <#.cpus>\t\t- number of cpus\n"
      printf "\t-m <mem.GB>\t\t- memory size\n"
      printf "\t-n <vm.name>\t\t- virtual machine name\n"
      printf "\t-t <cloudinit>\t\t- default/devel (check cloud-init/*.yaml files)\n"
      printf "\t-i <libvirt>\t\t- vanilla/numa/... (check libvirt/*.xmlfiles)\n"
      printf "\t-d <ubuntu.codename>\t- xenial/bionic/disco/eoan/focal (default: stable)\n"
      printf "\t-u <username>\t\t- as 1000:1000 in the installed vm (default: ubuntu)\n"
      printf "\t-l <launchpad_id>\t- for the ssh key import (default: rafaeldtinoco)\n"
      printf "\t-p <proxy>\t\t- proxy for http/https/ftp\n"
      printf "\t-r <repo.url>\t\t- url for the ubuntu mirror (default: br.archive)\n"
      printf "\t-o <isofile>\t\t- file containing iso image to be used as cdrom\n"
      printf "\t-k\t\t\t- do not attempt to install anything (livecd cases)\n"
      printf "\t-q\t\t\t- do not attempt to create qcow2 volumes (livecd cases)\n"
      printf "\t-w\t\t\t- wait until cloud-init is finished (after 1st boot)\n"
      printf "\n"
      exit 0
      ;;
    \?)
      echo "error: invalid option -$OPTARG" 1>&2
      exit 1
      ;;
    esac
  done

  shift $((OPTIND - 1))

  # mandatory options

  if [[ "$vcpus" == "" || "$ramgb" == "" || "$hostname" == "" ]]
  then
    exiterr "$0 -h for help"
  fi

  echo -n . ; sleep 1 ; echo -n . ; sleep 1 ; echo -n . ; sleep 1 ; echo
}

# usage function

usage() {

  if [[ "$0" =~ kvm.sh ]]
  then
    getoptkvm $@
  fi

}
