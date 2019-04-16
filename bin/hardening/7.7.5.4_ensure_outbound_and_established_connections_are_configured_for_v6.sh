#!/bin/bash

#
# harbian audit 9 Hardening
#

#
# 7.7.5.4 Ensure outbound and established connections are configured for v6 (Not Scored)
# For ipv6
# Add this feature:Author : Samson wen, Samson <sccxboy@gmail.com>
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=2

PROTOCOL_LIST="tcp udp icmp"
IP6VERSION="IPS6"
IPV6_ENABLE=1

RET_VALUE1=1
RET_VALUE2=1

# This function will be called if the script status is on enabled / audit mode
audit () {
	check_ipv6_is_enable
	IPV6_ENABLE=$FNRET
	if [ $IPV6_ENABLE -eq 0 ]; then
		for protocol in $PROTOCOL_LIST
		do
			# Check INPUT with ESTABLISHED is config
			check_input_with_established_is_accept "${protocol}" "$IP6VERSION"
			if [ $FNRET = 0 ]; then 
				RET_VALUE1=0
				info "Portocol $protocol INPUT is conf"
			else
				RET_VALUE1=1
				info "Portocol $protocol INPUT is not conf"
			fi
			# Check outbound is config
			check_outbound_connect_is_accept "${protocol}" $IP6VERSION
			if [ $FNRET = 0 ]; then 
				RET_VALUE2=0
				info "Portocol $protocol outbound is conf"
			else
				RET_VALUE2=1
				info "Portocol $protocol outbound is not conf"
			fi
		done

		if [ $RET_VALUE1 -eq 0 -a $RET_VALUE2 -eq 0 ]; then
			ok "Outbound and established connections are configured for v6."
		else
			crit "Outbound and established connections are not configured for v6."
		fi
	else
		ok "Ipv6 has set disabled, so pass."
	fi
}

# This function will be called if the script status is on enabled mode
apply () {
	if [ $IPV6_ENABLE -eq 0 ]; then
		for protocol in $PROTOCOL_LIST
		do
			# Apply INPUT with ESTABLISHED 
			check_input_with_established_is_accept "${protocol}" "$IP6VERSION"
			if [ $FNRET = 1 ]; then 
				warn "Portocol $protocol INPUT is not set, need the administrator to manually add it. Howto apply: ip6tables -A INPUT -p $protocol -m state --state ESTABLISHED -j ACCEPT"
			fi
			# Apply outbound 
			check_outbound_connect_is_accept "${protocol}" "$IP6VERSION"
			if [ $FNRET = 1 ]; then 
				warn "Portocol $protocol outbound is not set, need the administrator to manually add it. Howto apply: ip6tables -A OUTPUT -p $protocol -m state --state NEW,ESTABLISHED -j ACCEPT"
			fi
		done
	else
		ok "Ipv6 has set disabled, so pass."
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
