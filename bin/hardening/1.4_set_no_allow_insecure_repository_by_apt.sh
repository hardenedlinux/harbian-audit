#!/bin/bash

#
# harbian audit Debian 9 Hardening
#

#
# 1.4 Set no allow insecure repository when by apt update (Scored)
# Author : Samson wen, Samson <sccxboy@gmail.com>
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=2
OPTION='AllowInsecureRepositories'

# This function will be called if the script status is on enabled / audit mode
audit () {
    if [ $(grep -v "^#" /etc/apt/ -r | grep -c "${OPTION}.*true") -gt 0 ]; then
        crit "The allow insecure repository when by apt update is enable"
        FNRET=1
    else
        ok "The allow insecure repository when by apt update is disable"
        FNRET=0
    fi
}

# This function will be called if the script status is on enabled mode
apply () {
    if [ $FNRET = 0 ]; then 
        ok "The allow insecure repository when by apt update is disable"
    else
        warn "Set no allow insecure repository when by apt update"
        for CONFFILE in $(grep -i "${OPTION}" /etc/apt/ -r | grep -v "^#" | awk -F: '{print $1}')
        do
            sed -i "s/${OPTION}.*true.*/${OPTION} \"false\";/g" ${CONFFILE}
        done
    fi
}

# This function will check config parameters required
check_config() {
    # No parameters for this function
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
