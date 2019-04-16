#!/bin/bash

#
# harbian audit 9 Hardening
#

#
# 7.7.3 Ensure the Firewall is set rules of protect DOS attacks (Scored)
# Include ipv4 and ipv6
# Add this feature:Author : Samson wen, Samson <sccxboy@gmail.com>
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=2

IPS4=$(which iptables)
IPS6=$(which ip6tables)

IPV4_RET=1
IPV6_RET=1
IPV6_ISENABLE=1

# Quick note here : CIS recommends your iptables rules to be persistent. 
# Do as you want, but this script does not handle this

# This function will be called if the script status is on enabled / audit mode
audit () {
	# ipv4
    if [ $(${IPS4} -S | grep -E "\-m.*limit" | grep -Ec "\-\-limit-burst") -eq 0 ]; then
		info "Iptables is not set rules of protect DOS attacks!"
		IPV4_RET=1
	else
		info "Iptables has set rules for protect DOS attacks!"
		IPV4_RET=0
	fi
	# ipv6
	check_ipv6_is_enable
	IPV6_ISENABLE=$FNRET
	if [ $IPV6_ISENABLE = 0 ]; then 
    	if [ $(${IPS6} -S | grep -E "\-m.*limit" | grep -Ec "\-\-limit-burst") -eq 0 ]; then
			info "Ip6tables is not set rules of protect DOS attacks!"
			IPV6_RET=1
		else
			info "Ip6tables has set rules for protect DOS attacks!"
			IPV6_RET=0
		fi
	fi
	if [ $IPV6_ISENABLE -eq 0 ]; then
		if [ $IPV4_RET -eq 1 -o $IPV6_RET -eq 1 ]; then
			crit "Iptables/ip6tables is not set rules of protect DOS attacks!"
			FNRET=1
		else
			ok "Iptables/ip6tables has set rules for protect DOS attacks!"
			FNRET=0
		fi
	else
		if [ $IPV4_RET -eq 1 ]; then
			crit "Iptables is not set rules of protect DOS attacks!"
			FNRET=1
		else
			ok "Iptables has set rules for protect DOS attacks!"
			FNRET=0
		fi
	fi
}

# This function will be called if the script status is on enabled mode
apply () {
    if [ $FNRET = 0 ]; then
		if [ $IPV6_ISENABLE -eq 0 ]; then
        	ok "Iptables/Ip6tables has set rules for protect DOS attacks!"
		else
        	ok "Iptables has set rules for protect DOS attacks!"
		fi
    else
		if [ $IPV6_ISENABLE -eq 0 ]; then
        	warn "Iptables/Ip6tables is not set rules of protect DOS attacks! need the administrator to manually add it."
		else
        	warn "Iptables is not set rules of protect DOS attacks! need the administrator to manually add it."
		fi
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
