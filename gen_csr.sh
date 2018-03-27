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

dirname=$(dirname "${lets_public}/${name}")

if ! mkdir -p "${dirname}"
then
	echo "Directory ${dirname} cannot be created, run:"
	echo "install -d -o acme ${dirname}"
	exit 1
fi

if [ -e "${csr_name}" ]
then
	echo "CSR already exists : ${csr_name}"
	exit 1
fi

tlsa_hash=$(openssl rsa -in "${key_name}" -outform DER -pubout 2>/dev/null | openssl dgst -sha256 -binary | hexdump -ve '1/1 "%02x"')

: > "${lets_public}/${name}.tlsa"

tlsa_line() {
	printf '_443._tcp.%s. IN TLSA 3 1 1 %s\n' "${1}" "${tlsa_hash}" >> "${lets_public}/${name}.tlsa"
}

config=$(mktemp)
trap 'rm -f ${config}' EXIT

cat "$ssl_config" > "${config}"

echo "[SAN]" >> "${config}"

output="subjectAltName=DNS:$1"

tlsa_line "$1"

shift

for d in "$@"
do
	output="${output},DNS:${d}"
	tlsa_line "${d}"
done

echo "${output}" >> "${config}"

openssl req -new -sha256 -key "${key_name}" -subj "/" -reqexts SAN -config "${config}" > "${csr_name}"

chmod 444 "${csr_name}"
