#!/bin/bash

# "fixes" the environment by installing what is needed

if [ $UID -ne 0 ]; then
  sudo "$0" "$@" && exit 0 || exit 1
fi

scriptdir=$(dirname $0)

. $scriptdir/functions.sh
. $scriptdir/prereqs.sh

prereqs
