#!/bin/sh
# vim:sw=8 sts=8

set -e

dir=$(dirname "$0")
. "${dir}"/lets_path.sh

if [ $# -lt 1 ]
then
	echo "Usage: $0 [services...]"
	exit 1
fi

for cert in $(find "${lets_public}" -name '*.crt')
do
	if [ ! -f "${cert}" ]
	then
		echo "No certificate to renew"
		exit 1
	fi
	if ! openssl x509 -in "${cert}" -noout -checkend $((86400*renew)); then
		base=${cert#${lets_public}/}
		base=${base%.crt}
		case "${base}" in
			dns/*)
				"${dir}"/gen_one_dns.sh "${base#dns/}"
				;;
			*)
				"${dir}"/gen_one.sh "${base}"
				;;
		esac
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
