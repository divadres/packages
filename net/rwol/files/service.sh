#!/bin/sh
#.Distributed under the terms of the GNU General Public License (GPL) version 2.0
#.2014-2018 Christian Schoenebeck <christian dot schoenebeck at gmail dot com>
. $(dirname "$0")/functions.sh

create_dirs

OUTPUT="/var/run/$MYPROG/data.bin"
WOWPID="/var/run/$MYPROG/service.pid"
TCPPID="/var/run/$MYPROG/tcpdump.pid"
LOGFILE="/var/log/$MYPROG/service.log"
REQUESTSFILE="/var/log/$MYPROG/requests.log"

load_config "global"


case "$1" in
	start)	
		echo "Start"
		log "-----------------------------------------------------------------------"
		log "Started $MYPROG with PID: $$" 1
		log "Settings:"
		log " * enabled:             $enabled"
		log " * listen_interface:    $listen_interface"
		log " * listen_port:         $listen_port"
		log " * broadcast_interface: $broadcast_interface"
		log " * log_length:          $log_length"
		log " * requests_length:     $requests_length"
		
		[ -f $WOWPID ] && log "The service is already running with PID: `cat $WOWPID`!" && exit 0

		check_settings
		[ $? == 0 ] && log "-----------------------------------------------------------------------" && exit 0
		
		log "-----------------------------------------------------------------------"
		
		

		echo $$ > $WOWPID
		
		run_tcpdump
		listen_one_packet
	;;
	stop)
		[ -f $WOWPID ] &&  log "Stopping $MYPROG PID: `cat $WOWPID`"  1 && (eval "kill `cat $WOWPID` > /dev/null 2>&1" ; rm $WOWPID)
		[ -f $TCPPID ] &&  log "Stopping TCPDUMP PID: `cat $TCPPID`"  1 && (eval "kill `cat $TCPPID` > /dev/null 2>&1" ; rm $TCPPID)
		[ -f $OUTPUT ] &&  log "Clieaning data: $OUTPUT " 1 && rm $OUTPUT
		exit 1
	;;
esac