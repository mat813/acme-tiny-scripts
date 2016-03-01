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

if [ ! -e ${lets_private}/account.key ]
then
	echo "Account key does not exist : ${lets_private}/account.key"
	echo "Maybe run ./gen_key.sh account"
	exit 1
fi

if [ ! -e ${lets_private}/${name}.key ]
then
	echo "Key does not exist : ${lets_private}/${name}.key"
	echo "Maybe run ./gen_key.sh ${name}"
	exit 1
fi

if [ ! -e ${lets_private}/${name}.csr ]
then
	echo "CSR does not exist : ${lets_private}/${name}.csr"
	echo "Maybe run ./gen_csr.sh ${name} domains..."
	exit 1
fi

if [ ! -d ${challenges} ]
then
	echo "Challenge directory does not exist. You need to run, as root:"
	echo "install -d -o $USERNAME -g wheel -m 0755 ${challenges}"
	exit 1
fi

if [ ! -e ${lets_public}/intermediate.pem ]
then
	fetch -qo ${lets_public}/intermediate.pem https://letsencrypt.org/certs/lets-encrypt-x1-cross-signed.pem
fi

cert=`mktemp`
trap 'rm -f ${cert}' EXIT

/usr/local/bin/acme_tiny --account-key ${lets_private}/account.key --csr ${lets_private}/${name}.csr --acme-dir ${challenges} > ${cert}

cat ${cert} > ${lets_public}/${name}.crt
cat ${cert} ${lets_public}/intermediate.pem > ${lets_public}/${name}.bundle
