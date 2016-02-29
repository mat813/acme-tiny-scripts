#!/bin/sh

set -e

. lets_path.sh

if [ $# -lt 2 ]
then
	echo "Usage: $0 [filename] [domains...]"
	exit 1
fi

name=$1

shift

if [ ! -e ${lets_private}/${name}.key ]
then
	echo "Key file does not exist : ${lets_private}/${name}.key"
	exit 1
fi

if [ -e ${lets_private}/${name}.csr ]
then
	echo "CSR already exists : ${lets_private}/${name}.csr"
	exit 1
fi

config=`mktemp`
trap "rm -f ${config}" EXIT

cat /etc/ssl/openssl.cnf > ${config}

echo "[SAN]" >> ${config}

output="subjectAltName=DNS:$1"

shift

for d in $@
do
	output="${output},DNS:${d}"
done

echo "${output}" >> ${config}

openssl req -new -sha256 -key ${lets_private}/${name}.key -subj "/" -reqexts SAN -config ${config} > ${lets_private}/${name}.csr
