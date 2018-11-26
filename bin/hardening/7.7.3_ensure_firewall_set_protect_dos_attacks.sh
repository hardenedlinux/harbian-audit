#!/bin/bash

#
# harbian audit 9  Hardening
#

#
# 7.7.2 Ensure the Firewall is set rules of protect DOS attacks (Scored)
# Add this feature:Authors : Samson wen, Samson <sccxboy@gmail.com>
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=2

# Quick note here : CIS recommends your iptables rules to be persistent. 
# Do as you want, but this script does not handle this

PARAM='SETDOS'

# This function will be called if the script status is on enabled / audit mode
audit () {
    check_iptables_set ${PARAM}
    echo "fffffffffffffffffffffffffffffffffffff"
    if [ $FNRET != 0 ]; then
        crit "Iptables is not set rules of protect DOS attacks!"
        FNRET=1
    else
        ok "Iptables has set rules for protect DOS attacks!"
        FNRET=0
    fi
}

# This function will be called if the script status is on enabled mode
apply () {
    if [ $FNRET = 0 ]; then
        ok "Iptables has set rules for protect DOS attacks!"
    else
        warn "Iptables is not set rules of protect DOS attacks! need the administrator to manually add it."
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
