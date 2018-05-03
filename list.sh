#!/bin/sh
# vim:sw=8 sts=8

set -e

dir=$(dirname "$0")
. "${dir}"/lets_path.sh
. "${dir}"/config.sh

if [ -t 1 ]
then
	NC='\033[0m'
	RED='\033[0;31m'
	LRED='\033[1;31m'
	GREEN='\033[0;32m'
	LGREEN='\033[1;32m'
	ORANGE='\033[0;33m'
	LORANGE='\033[1;33m'
	BLUE='\033[0;34m'
	LBLUE='\033[1;34m'
	PURPLE='\033[0;35m'
	LPURPLE='\033[1;35m'
	CYAN='\033[0;36m'
	LCYAN='\033[1;36m'
	GRAY='\033[0;37m'
	WHITE='\033[1;37m'
fi

echo '-------------------------------------------------------------------------------'
echo 'Found the following certs:'

find -s "${lets_public}" -name '*.crt' | while read -r cert
do
	base=${cert#${lets_public}/}
	domains=$(openssl x509 -noout -in "${cert}" -text|xargs -n 1|sed -ne 's/,$//; s/DNS://p;'|xargs)
	endDate=$(openssl x509 -noout -in "${cert}" -enddate|sed -e 's/notAfter=//')
	seconds=$(LANG=C date -j -f "%b %d %T %Y GMT" "${endDate}" +%s)
	remain=$((seconds-$(date +%s)))

	printf "  Certificate Name: ${BLUE}%s${NC}\\n"  "${base%.crt}"
	printf "    Domains: ${GRAY}%s${NC}\\n" "${domains}"
	printf "    Expiry Date: %s " "${endDate}"
	if [ $remain -ge $((renew*86400)) ]
	then
		printf " ${GREEN}(VALID: %d days)${NC}\\n" $((remain/86400))
	elif [ $remain -ge $((warning*86400)) ]
	then
		printf " ${LORANGE}(VALID: %d days)${NC}\\n" $((remain/86400))
	elif [ $remain -ge $((warning*86400)) ]
	then
		printf " ${ORANGE}(VALID: %d days)${NC}\\n" $((remain/86400))
	elif [ $remain -ge $((critical*86400)) ]
	then
		printf " ${RED}(VALID: %d days)${NC}\\n" $((remain/86400))
	elif [ $remain -ge 0 ]
	then
		printf "${RED}(VALID: %d hours)${NC}\\n" $((remain/3600))
	else
		printf "${LRED}(INVALID)${NC}\\n"
	fi
	if [ "${base}" != "${base#dns/}" ]
	then
		base=${base#dns/}
	fi
	printf "    Certificate Path: ${PURPLE}%s${NC}\\n" "${cert}"
	printf "    Private Key Path: ${PURPLE}%s/%s.key${NC}\\n" "${lets_private}" "${base%.crt}"
done

echo '-------------------------------------------------------------------------------'
