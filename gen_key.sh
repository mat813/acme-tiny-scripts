#!/bin/sh

set -e

. lets_path.sh

if [ $# -ne 1 ]
then
	echo "Usage: $0 [filename]"
	exit 1
fi

name=$1

shift

if [ -e $lets_private/$name.key ]
then
	echo "Key already exists : $lets_private/$name.key"
	exit 1
fi

openssl genrsa 4096 > $lets_private/$name.key
