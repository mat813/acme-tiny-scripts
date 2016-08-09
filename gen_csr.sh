#!/bin/sh
# vim:sw=8 sts=8

set -e

dir=$(dirname "$0")
. "${dir}"/lets_path.sh

if [ $# -lt 2 ]
then
	echo "Usage: $0 [filename] [domains...]"
	exit 1
fi

name=$1

shift

key_name=${lets_private}/${name}.key
csr_name=${lets_private}/${name}.csr

if [ ! -e "${key_name}" ]
then
	echo "Key file does not exist : ${key_name}, generate it with"
	echo "${dir}/gen_key.sh ${name}"
	exit 1
fi

if [ -e "${csr_name}" ]
then
	echo "CSR already exists : ${csr_name}"
	exit 1
fi

config=$(mktemp)
trap 'rm -f ${config}' EXIT

cat "$ssl_config" > "${config}"

echo "[SAN]" >> "${config}"

output="subjectAltName=DNS:$1"

shift

for d in "$@"
do
	output="${output},DNS:${d}"
done

echo "${output}" >> "${config}"

openssl req -new -sha256 -key "${key_name}" -subj "/" -reqexts SAN -config "${config}" > "${csr_name}"

chmod 444 "${csr_name}"
