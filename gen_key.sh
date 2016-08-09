#!/bin/sh
# vim:sw=8 sts=8

set -e

dir=$(dirname "$0")
. "${dir}"/lets_path.sh

if [ $# -ne 1 ]
then
	echo "Usage: $0 [filename]"
	exit 1
fi

name=$1

shift

key_name=${lets_private}/${name}.key

if [ ! -e "${lets_private}/account.key" -a "$name" != "account" ]
then
	echo "The account key does not exist, start by creating it, with:"
	echo "${dir}/${0} account"
	exit 1
fi

if [ -e "${key_name}" ]
then
	echo "Key already exists : ${key_name}"
	exit 1
fi

openssl genrsa 4096 > "${key_name}"

if [ "$name" != "account" ]
then
	chmod 444 "${key_name}"
else
	chmod 400 "${key_name}"
fi
