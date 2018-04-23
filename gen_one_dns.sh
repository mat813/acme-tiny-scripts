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
csr_name=${lets_private}/${name}.csr

if [ -x "${dns_auth_hook}" ] && [ -x "${dns_cleanup_hook}" ]
then
	crt_name=${lets_public}/dns/${name}.crt
	chain_name=${lets_public}/dns/${name}.chain
	bundle_name=${lets_public}/dns/${name}.bundle
	txt_name=${lets_public}/dns/${name}.txt

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

	cat "${cert}" > "${crt_name}"
	cat "${cert}.chain" > "${chain_name}"
	cat "${cert}.bundle" > "${bundle_name}"

	openssl x509 -noout -text -in "${cert}" > "${txt_name}"
elif [ -n "${dns_url}" ] && [ -n "${dns_login}" ] && [ -n "${dns_password}" ]
then
	crt_name=${lets_public}/dns/${name}.crt
	chain_name=${lets_public}/dns/${name}.chain
	bundle_name=${lets_public}/dns/${name}.bundle
	txt_name=${lets_public}/dns/${name}.txt
	tlsa_name=${lets_public}/${name}.tlsa
	for ext in key crt chain bundle tlsa
	do
		tmp=$(mktemp)
		#--header 'If-Modified-Since: Tue, 27 Mar 2018 14:31:08 GMT'
		if curl --fail --silent -o "${tmp}"  --user "${dns_login}:${dns_password}"  "${dns_url}/${name}.${ext}"
		then
			eval file='${'${ext}'_name}'
			if [ ! -s "${tmp}" ]
			then
				echo "file ${name}.${ext} empty !"
				continue
			fi
			if ! cmp -s "${tmp}" "${file}"
			then
				mkdir -p "$(dirname "${file}")"
				cat "${tmp}" > "${file}"
				if [ "${ext}" = crt ]
				then
					openssl x509 -noout -text -in "${crt_name}" > "${txt_name}"
				fi
			fi
			rm -f "${tmp}"
		else
			echo "${name}.${ext} not found"
		fi
	done
else
	echo "Either set the hook to executables or set dns_url/login/password"
	exit 1
fi
