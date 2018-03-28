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

if [ -x "${dns_auth_hook}" ] && [ -x "${dns_cleanup_hook}" ]
then
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

	dirname=$(dirname "${lets_public}/dns/${name}")

	if ! mkdir -p "${dirname}"
	then
		echo "Directory ${dirname} cannot be created, run:"
		echo "install -d -o acme ${dirname}"
		exit 1
	fi

	cert=$(mktemp -u)
	trap 'rm -f ${cert} ${cert}.chain ${cert}.bundle' EXIT

	/usr/local/bin/certbot certonly \
		--manual \
		--non-interactive \
		--quiet \
		--manual-public-ip-logging-ok \
		--agree-tos \
		--server https://acme-v02.api.letsencrypt.org/directory \
		--preferred-challenges=dns \
		--config-dir "${lets_private}/dns" \
		--work-dir /var/db/letsencrypt/dns \
		--logs-dir /var/log/letsencrypt/dns \
		--manual-auth-hook "${dns_auth_hook}" \
		--manual-cleanup-hook "${dns_cleanup_hook}" \
		--csr "${csr_name}" \
		--cert-path "${cert}" \
		--chain-path "${cert}.chain" \
		--fullchain-path "${cert}.bundle"

	cat "${cert}" > "${lets_public}/dns/${name}.crt"
	cat "${cert}.chain" > "${lets_public}/dns/${name}.chain"
	cat "${cert}.bundle" > "${lets_public}/dns/${name}.bundle"

	openssl x509 -noout -text -in "${cert}" > "${lets_public}/dns/${name}.txt"
else
	echo "One of the hooks is not executable."
	exit 1
fi
