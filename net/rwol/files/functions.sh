#!/bin/sh
#.Distributed under the terms of the GNU General Public License (GPL) version 2.0

. /lib/functions.sh

VERSION="1.0.0"
MYPROG="rwol"

load_config(){
	local __SECTION="$1"
	local __CURRENT_SECTION
		
	config_cb(){
		__CURRENT_SECTION="$2"
	}
	
	option_cb() {
		[ "$__CURRENT_SECTION" == "$__SECTION" ] && config_get "$1" "$__SECTION" "$1"
	}
	
	config_load "$MYPROG"
	return 0	
}

get_services(){
	local __SERVICES=""
	config_cb() {
		[ "$1" == "service" ] && __SERVICES="$__SERVICES $2"
	}
	config_load "$MYPROG"
	eval "$1=\"$__SERVICES\""
	return 0	
}


run_tcpdump(){
	[ -e $OUTPUT ] && rm  $OUTPUT
	eval "tcpdump -c 1 -i $listen_interface 'port $listen_port' -X -w $OUTPUT > /dev/null 2>&1 &" 
	echo "$!" > $TCPPID
	log "Starting TCPDUMP | PID: $! | Interface: $listen_interface | Port: $listen_port" 1
}


log(){
	if [ -f $LOGFILE ]; then
		data="`tail -$log_length $LOGFILE`\n"
	else
		data=""
	fi
	if [ -f $2 ] ; then
		echo -e "$data$1" > $LOGFILE
	else
		echo -e "$data$(date +"%m/%d/%Y %H:%M:%S") | $1" > $LOGFILE
	fi
	
	
}

request_log(){
	if [ -f $REQUESTSFILE ]; then
		data="`tail -$requests_length $REQUESTSFILE`\n"
	else
		data=""
	fi
	
	echo -e "$data[\"$1\", \"$2\", \"$3\", \"$4\", \"$5\", \"$6\", \"$7\"]" > $REQUESTSFILE
}


listen_one_packet(){
	log "Waiting for TCPDUMP finished..." 1

	while [ -n `cat $TCPPID` -a -e /proc/`cat $TCPPID` ] ; do
		sleep 1
	done
	
	if [ ! -s $OUTPUT ] ; then
		log "TCPDUMP finished, no data avaiable." 1
		run_tcpdump
		listen_one_packet
		return
	else
		log "TCPDUMP finished, reading data." 1
	fi
	
	hex_data=`cat $OUTPUT | hexdump -ve '/1 "%02x"'`

	if [ ${hex_data:108:2} == "45" ]; then # IPv4
		host="$((0x${hex_data:132:2})).$((0x${hex_data:134:2})).$((0x${hex_data:136:2})).$((0x${hex_data:138:2}))"
		mac="${hex_data:176:2}:${hex_data:178:2}:${hex_data:180:2}:${hex_data:182:2}:${hex_data:184:2}:${hex_data:186:2}"
	else
		log "IPv6 not supported." 1
		run_tcpdump
		listen_one_packet
		return
	fi
	
	log "Packet received from '$host' to '$mac'" 1
	request_log $(date +"%m/%d/%Y %H:%M:%S") $host $listen_port $listen_interface $broadcast_interface $mac

	log "Broadcasting wake on lan to $mac..." 1
	eval "etherwake -i '$broadcast_interface' $mac" 1
	run_tcpdump
	listen_one_packet
}

check_settings(){
	if [ "$enabled" == 0 ]; then
		log "$MYPROG is disabled!"
		return 0
	fi
	
	if [ -z "$listen_interface" ] || [ -z "$listen_port" ] || [ -z "$broadcast_interface" ]; then
		log "The settings are not valid!"
		return 0
	fi
	return 1
}

create_dirs(){
	[ ! -d "/var/log/rwol" ] && mkdir "/var/log/rwol" 
	[ ! -d "/var/run/rwol" ] && mkdir "/var/run/rwol" 
}

