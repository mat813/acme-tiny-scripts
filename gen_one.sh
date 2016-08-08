#!/bin/sh

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
csr_name=${lets_private}/${name}.csr

if [ ! -e "${lets_private}/account.key" ]
then
	echo "Account key does not exist : ${lets_private}/account.key"
	echo "Maybe run ./gen_key.sh account"
	exit 1
fi

if [ ! -e "${key_name}" ]
then
	echo "Key does not exist : ${key_name}"
	echo "Maybe run ./gen_key.sh ${name}"
	exit 1
fi

if [ ! -e "${csr_name}" ]
then
	echo "CSR does not exist : ${csr_name}"
	echo "Maybe run ./gen_csr.sh ${name} domains..."
	exit 1
fi

fetch -qo "${lets_public}/intermediate.pem" https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem

cert=$(mktemp)
trap 'rm -f ${cert}' EXIT

/usr/local/bin/acme_tiny --account-key "${lets_private}/account.key" --csr "${csr_name}" --acme-dir "${challenges}" > "${cert}"

cat "${cert}" > "${lets_public}/${name}.crt"
cat "${cert}" "${lets_public}/intermediate.pem" > "${lets_public}/${name}.bundle"
