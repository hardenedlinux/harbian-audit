#!/bin/bash

#
# harbian audit 9 Hardening
#

#
# 7.7.7 Ensure outbound and established connections are configured (Not Scored)
# Include ipv4 and ipv6
# Add this feature:Author : Samson wen, Samson <sccxboy@gmail.com>
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=2

PROTOCOL_LIST="tcp udp icmp"

# This function will be called if the script status is on enabled / audit mode
audit () {
	for protocol in $PROTOCOL_LIST
	do
		# Check INPUT with ESTABLISHED is config
		check_input_with_established_is_accept "${protocol}"
		if [ $FNRET = 0 ]; then 
			ok "Portocol $protocol INPUT is conf"
		else
			crit "Portocol $protocol INPUT is not conf"
		fi
		# Check outbound is config
		check_outbound_connect_is_accept "${protocol}"
		if [ $FNRET = 0 ]; then 
			ok "Portocol $protocol outbound is conf"
		else
			crit "Portocol $protocol outbound is not conf"
		fi
	done
}

# This function will be called if the script status is on enabled mode
apply () {
	for protocol in $PROTOCOL_LIST
	do
		# Apply INPUT with ESTABLISHED 
		check_input_with_established_is_accept "${protocol}"
		if [ $FNRET = 1 ]; then 
			warn "Portocol $protocol INPUT is not set, need the administrator to manually add it. Howto apply: iptables -A INPUT -p $protocol -m state --state ESTABLISHED -j ACCEPT"
		fi
		# Apply outbound 
		check_outbound_connect_is_accept "${protocol}"
		if [ $FNRET = 1 ]; then 
			warn "Portocol $protocol outbound is not set, need the administrator to manually add it. Howto apply: iptables -A OUTPUT -p $protocol -m state --state NEW,ESTABLISHED -j ACCEPT"
		fi
	done
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
