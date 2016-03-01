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

for c in ${lets_public}/*.crt
do
	if [ ! -f "${c}" ]
	then
		echo "No certificate to check"
		exit ${STATE_UNKNOWN}
	fi
	if ! openssl x509 -in "${c}" -noout -checkend $((86400*WARNING))
	then
		b=$(basename "${c}" .crt)
		if ! openssl x509 -in "${c}" -noout -checkend $((86400*CRITICAL))
		then
			warn="${warn} ${b}"
		else
			crit="${crit} ${b}"
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
