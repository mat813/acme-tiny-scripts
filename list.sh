#!/bin/sh
# vim:sw=8 sts=8

set -e

dir=$(dirname "$0")
. "${dir}"/lets_path.sh

echo '-------------------------------------------------------------------------------'
echo 'Found the following certs:'

find -s "${lets_public}" -name '*.crt' | while read -r cert
do
	base=${cert#${lets_public}/}
	domains=$(openssl x509 -noout -in "${cert}" -text|xargs -n 1|sed -ne 's/,$//; s/DNS://p;'|xargs)
	endDate=$(openssl x509 -noout -in "${cert}" -enddate|sed -e 's/notAfter=//')
	seconds=$(LANG=C date -j -f "%b %d %T %Y GMT" "${endDate}" +%s)
	remain=$((seconds-$(date +%s)))

	printf "  Certificate Name: %s\\n"  "${base%.crt}"
	printf "    Domains: %s\\n" "${domains}"
	if [ $remain -ge 172800 ]
	then
		printf "    Expiry Date: %s (VALID: %d days)\\n" "${endDate}" $((remain/86400))
	elif [ $remain -ge 0 ]
	then
		printf "    Expiry Date: %s (VALID: %d hours)\\n" "${endDate}" $((remain/3600))
	else
		printf "    Expiry Date: %s (INVALID)\\n" "${endDate}"
	fi
	printf "    Certificate Path: %s\\n" "${cert}"
	if [ "${base}" = "${base#dns/}" ]
	then
		printf "    Private Key Path: %s/%s.key\\n" "${lets_private}" "${base%.crt}"
	else
		base=${base#dns/}
		printf "    Private Key Path: %s/%s.key\\n" "${lets_private}" "${base%.crt}"
	fi
done

echo '-------------------------------------------------------------------------------'
