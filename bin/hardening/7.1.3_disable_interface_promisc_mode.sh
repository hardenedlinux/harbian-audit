#!/bin/bash

#
# harbian audit 7/8/9/10 or CentOS  Hardening
#

#
# 7.1.3 Disable promiscuous mode for network interface (Scored)
# Author : Samson wen, Samson <sccxboy@gmail.com>
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=2

KEYWORD='promisc'

# This function will be called if the script status is on enabled / audit mode
audit () {
    COUNT=$(ip link | grep -i "${KEYWORD}" | wc -l)
    if [ $COUNT -gt 0 ]; then
        crit "The total number of network interfaces with ${KEYWORD} mode set is ${COUNT}"
        FNRET=1
    else
        ok "Not set ${KEYWORD} mode for network interface in the system."
        FNRET=0
    fi
}

# This function will be called if the script status is on enabled mode
apply () {
    if [ $FNRET != 0 ]; then
        warn "Disable promiscuous mode for network interface"
        for INTERFACE in $(ip link | grep -i  promisc | awk -F: '{print $2}')
        do
            ip link set dev ${INTERFACE} multicast off promisc off
        done
    else
        ok "Not set ${KEYWORD} mode for network interface in the system."
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
