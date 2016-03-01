#!/bin/sh

set -e

dir=$(dirname "$0")
. "${dir}"/lets_path.sh

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
STATE_DEPENDENT=4

CRITICAL=25
WARNING=50

for cert in ${lets_public}/*.crt
do
	if [ ! -f "${cert}" ]
	then
		echo "No certificate to check"
		exit ${STATE_UNKNOWN}
	fi
	if ! openssl x509 -in "${cert}" -noout -checkend $((86400*WARNING))
	then
		base=$(basename "${cert}" .crt)
		if ! openssl x509 -in "${cert}" -noout -checkend $((86400*CRITICAL))
		then
			warn="${warn} ${base}"
		else
			crit="${crit} ${base}"
		fi
	fi
done

if [ -n "${crit}" ]
then
	echo "Certificates for${crit} expire in less than ${CRITICAL} days"
	exit ${STATE_CRITICAL}
fi

if [ -n "${warn}" ]
then
	echo "Certificates for${crit} expire in less than ${WARNING} days"
	exit ${STATE_WARNING}
fi

echo "All certificates expire in more than ${WARNING} days."
exit ${STATE_OK}
