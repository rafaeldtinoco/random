#!/bin/bash

# check all arguments given to iso script

getoptiso() {

  while getopts ":n:c:d:l:u:r:o:h" opt; do
    case ${opt} in
    n)
      hostname=$OPTARG
      echo "option: hostname=$hostname"
      ;;
    c)
      cloudimg=$OPTARG
      echo "option: cloudimg=$cloudimg"
      ;;
    d)
      distro=$OPTARG
      echo "option: distro=$distro"
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
    o)
      offlinepkgs="$OPTARG"
      echo "option: offlinepkgs=$offlinepkgs"
      ;;
    h)
      printf "\n"
      printf "syntax: $0 [options]\n"
      printf "\n"
      printf "options:\n"
      printf "\t-n <hostname>\t\t- OS hostname\n"
      printf "\t-c <ubuntu cloud img>\t- https://cloud-images.ubuntu.com/releases/.../release/*-root.tar.xz\n"
      printf "\t\t\t\t  * default: ubuntu-18.04-server-cloudimg-amd64-root.tar.xz *\n"
      printf "\t-d <livecd version>\t- xenial/bionic/disco/eoan/focal (default: stable)\n"
      printf "\t-u <username>\t\t- as 1000:1000 in the installed vm (default: ubuntu)\n"
      printf "\t-l <launchpad_id>\t- for the ssh key import (default: rafaeldtinoco)\n"
      printf "\t-r <repo.url>\t\t- url for the ubuntu mirror (default: us.archive)\n"
      printf "\t-o <offlinepkgs>\t- format: package01,package02,package03\n"
      printf "\t\t\t\t  * these pkgs be part of a local repository in livecd *\n"
      printf "\n"
  cloudimg=
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

  if [[ "$hostname" == "" ]];
  then
    exiterr "$0 -h for help"
  fi

  echo -n . ; sleep 1 ; echo -n . ; sleep 1 ; echo -n . ; sleep 1 ; echo
}

# usage function

usage() {

  if [[ "$0" =~ iso.sh ]]
  then
    getoptiso $@
  fi

}
