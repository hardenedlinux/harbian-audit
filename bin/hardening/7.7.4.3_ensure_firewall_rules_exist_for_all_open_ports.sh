#!/bin/bash

#
# harbian audit 9 Hardening
#

#
# 7.7.4.3 Ensure default deny firewall policy (Scored)
# For ipv4 
# Add this feature:Author : Samson wen, Samson <sccxboy@gmail.com>
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=2

IPS4=$(which iptables)

NETLISTENLIST="/dev/shm/7.7.4.3"
PROTO_PORT="/dev/shm/proto_port_pair"

# This function will be called if the script status is on enabled / audit mode
audit () {
	# For ipv4 
	rm -f $NETLISTENLIST
	rm -f $PROTO_PORT
	netstat -ln | egrep -w '^tcp|^udp' > $NETLISTENLIST
	cat $NETLISTENLIST | while read LISTENING
	do
		PROTO_TYPE=$(echo ${LISTENING} | awk '{print $1}')
		LISTEN_PORT=$(echo ${LISTENING} | awk '{print $4}' | awk -F: '{print $2}')
		if [ $($IPS4 -S | grep "^\-A INPUT \-p $PROTO_TYPE" | grep -c "\-\-dport $LISTEN_PORT \-m state \-\-state NEW \-j ACCEPT") -ge 1 ]; then
        	info "Service: protocol $PROTO_TYPE listening port $LISTEN_PORT was set firewall rules."
		else	
			echo "${PROTO_TYPE} ${LISTEN_PORT}" >> $PROTO_PORT
			info "Service: protocol $PROTO_TYPE listening port $LISTEN_PORT is not set firewall rules."
		fi
	done
	rm -f $NETLISTENLIST
    if [ -f $PROTO_PORT ]; then
        crit "Iptables is not set firewall rules exist for all open ports!"
	else
        ok "Iptables has set firewall rules exist for all open ports!"
	fi
}

# This function will be called if the script status is on enabled mode
apply () {
    if [ -f $PROTO_PORT ]; then
		cat $PROTO_PORT | while read NOSETPAIR
		do
			PROTO_TYPE=$(echo ${NOSETPAIR} | awk '{print $1}')
			LISTEN_PORT=$(echo ${NOSETPAIR} | awk '{print $2}')
			warn "Service: protocol $PROTO_TYPE listening port $LISTEN_PORT is not set firewall rules, need the administrator to manually add it. Howto set: iptables -A INPUT -p <protocol> --dport <port> -m state --state NEW -j ACCEPT"
		done
		rm -f $PROTO_PORT 
    else
        ok "Iptables has set firewall rules exist for all open ports!"
    fi
}

# This function will check config parameters required
check_config() {
    :
}

# Source Root Dir Parameter
if [ -r /etc/default/cis-hardening ]; then
    . /etc/default/cis-hardening
fi
if [ -z "$CIS_ROOT_DIR" ]; then
     echo "There is no /etc/default/cis-hardening file nor cis-hardening directory in current environment."
     echo "Cannot source CIS_ROOT_DIR variable, aborting."
    exit 128
fi

# Main function, will call the proper functions given the configuration (audit, enabled, disabled)
if [ -r $CIS_ROOT_DIR/lib/main.sh ]; then
    . $CIS_ROOT_DIR/lib/main.sh
else
    echo "Cannot find main.sh, have you correctly defined your root directory? Current value is $CIS_ROOT_DIR in /etc/default/cis-hardening"
    exit 128
fi
