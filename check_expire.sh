#!/bin/sh
# vim:sw=8 sts=8

set -e

dir=$(dirname "$0")
. "${dir}"/lets_path.sh

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
STATE_DEPENDENT=4

crts=0

for cert in $(find "${lets_public}" -name '*.crt')
do
	if [ ! -f "${cert}" ]
	then
		echo "No certificate to check"
		exit ${STATE_UNKNOWN}
	fi
	crts=$((crts+1))
	if ! openssl x509 -in "${cert}" -noout -checkend $((86400*warning))
	then
		base=$(basename "${cert}" .crt)
		if ! openssl x509 -in "${cert}" -noout -checkend $((86400*critical))
		then
			crit="${crit} ${base}"
		else
			warn="${warn} ${base}"
		fi
	fi
done

if [ -n "${crit}" ]
then
	echo "Certificates for${crit} expire in less than ${critical} days"
	exit ${STATE_CRITICAL}
fi

if [ -n "${warn}" ]
then
	echo "Certificates for${warn} expire in less than ${warning} days"
	exit ${STATE_WARNING}
fi

echo "${crts} certificates expire in more than ${warning} days."
exit ${STATE_OK}
