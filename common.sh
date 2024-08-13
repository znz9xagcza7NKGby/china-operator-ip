#!/usr/bin/env bash

[[ $DEBUG == true ]] && set -x

log_info(){
	>&2 echo "INFO>" $@
}

get_asn(){
	local CONF_FILE=$1
	unset PATTERN
	unset COUNTRY
	unset EXCLUDE
	source $CONF_FILE
	EXCLUDE=${EXCLUDE:-"^$"}
	grep -P "${COUNTRY}\$" asnames.txt |
	grep -Pi "$PATTERN" |
	grep -vPi "$EXCLUDE" |
	awk '{gsub(/AS/, ""); print $1 }'
}

prepare_data(){
	curl -sSL https://bgp.potaroo.net/cidr/autnums.html | awk '-F[<>]' '{print $3,$5}' | grep '^AS' > asnames.txt
	bgpkit-broker latest -c rrc00 --json | jq -c '.[] | select( .data_type | contains("rib")) | .url' | head -n 1 | xargs axel -q -o rib.gz
	stat rib.gz
	log_info "runing bgpdump..."
	bgpdump -m -O rib.txt rib.gz
	stat rib.txt
	log_info "finish bgpdump"
}

wait_exit(){
       local oldstate=$(set +o)
       set +e
       local s=0
       while [[ $s -ne 127 ]]; do
               [[ $s -ne 0 ]] && exit $s
               wait -n
               s=$?
       done
       eval "$oldstate"
       return 0
}
