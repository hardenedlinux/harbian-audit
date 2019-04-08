#!/bin/bash

#
# harbian audit 9 Hardening
#

#
# 7.7.4 Ensure default deny firewall policy (Scored)
# Include ipv4 and ipv6
# Add this feature:Authors : Samson wen, Samson <sccxboy@gmail.com>
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=2

IPS4=$(which iptables)
IPS6=$(which ip6tables)

# This function will be called if the script status is on enabled / audit mode
audit () {
    if [ $(${IPS4} -S | egrep "\-P") -eq 0 ]; then
		crit "Ip4tables: Firewall policy is not default deny!"
		if [ $(${IPS6} -S | egrep "\-P") -eq 0 ]; then
			crit "Ip6tables: Firewall policy is not default deny!"
			FNRET=1
		else
			ok "Ip6tables has set default deny for firewall policy!"
			FNRET=0
		fi
	else
		ok "Ip4tables has set default deny for firewall policy!"
		FNRET=0
	fi
}

# This function will be called if the script status is on enabled mode
apply () {
    if [ $FNRET = 0 ]; then
        ok "Iptables/Ip6tables has set default deny for firewall policy!"
    else
        warn "Iptables/Ip6tables is not set default deny for firewall policy! need the administrator to manually add it. Howto set: iptables/ip6tables -P INPUT DROP; iptables/ip6tables -P OUTPUT DROP; iptables/ip6tables -P FORWARD DROP."
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
