#!/bin/bash

#
# harbian audit 9 Hardening
#

#
# 7.7.2 Ensure the Firewall is set rules (Scored)
# Include ipv4 and ipv6
# Add this feature:Author : Samson wen, Samson <sccxboy@gmail.com> 
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=2

IPS4=$(which iptables)
IPS6=$(which ip6tables)

# Quick note here : CIS recommends your iptables rules to be persistent. 
# Do as you want, but this script does not handle this

# This function will be called if the script status is on enabled / audit mode
audit () {
    if [ $(${IPS4} -S | grep -Ec "^-A|^-I") -eq 0 -o $(${IPS6} -S | grep -Ec "^-A|^-I") -eq 0 ]; then
        crit "Iptables/Ip6tables is not set rule!"
        FNRET=1
    else
        ok "Ip4tables rules are set!"
        FNRET=0
    fi
}

# This function will be called if the script status is on enabled mode
apply () {
    if [ $FNRET = 0 ]; then
        ok "Iptables/Ip6tables rules are set!"
    else
        warn "Iptables/Ip6tables rules are not set, need the administrator to manually add it."
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
