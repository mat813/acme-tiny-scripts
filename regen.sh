#!/bin/sh

set -e

dir=$(dirname "$0")
. "${dir}"/lets_path.sh

if [ $# -lt 1 ]
then
	echo "Usage: $0 [services...]"
	exit 1
fi

if [ ! -e "${lets_private}/account.key" ]
then
	echo "Account key does not exist : ${lets_private}/account.key"
	echo "Maybe run ./gen_key.sh account"
	exit 1
fi

for cert in ${lets_public}/*.crt
do
	if [ ! -f "${cert}" ]
	then
		echo "No certificate to renew"
		exit 1
	fi
	if ! openssl x509 -in "${cert}" -noout -checkend $((86400*renew)); then
		base=$(basename "${cert}" .crt)
		"${dir}"/gen_one.sh "${base}"
	fi
done

# If base is set, it means we did renew at least one certificate, so, reload
# the services.
if [ -n "${base}" ]; then
	for s in "$@"
	do
		sudo /usr/sbin/service "${s}" reload
	done
fi
