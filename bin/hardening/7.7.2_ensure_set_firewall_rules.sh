#!/bin/bash

#
# harbian audit 9  Hardening
#

#
# 7.7.2 Ensure the Firewall is set rules (Scored)
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=2

# Quick note here : CIS recommends your iptables rules to be persistent. 
# Do as you want, but this script does not handle this

PARAM='SETRULE'

# This function will be called if the script status is on enabled / audit mode
audit () {
    check_iptables_set ${PARAM}
    if [ $FNRET != 0 ]; then
        crit "Iptables is not set rule!"
    else
        ok "Iptables rules are set!"
    fi
}

# This function will be called if the script status is on enabled mode
apply () {
    if [ $FNRET = 0 ]; then
        ok "Iptables rules are set!"
    else
        warn "Iptables rules are not set, need the administrator to manually add it."
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
