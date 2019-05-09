#!/bin/bash

#
# harbian audit 9 Hardening
#

#
# 8.4.2 Implement Periodic Execution of File Integrity (Scored)
# Modify by:
# Samson-W (sccxboy@gmail.com)
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=4

FILES='/etc/cron.daily/aide'

# This function will be called if the script status is on enabled / audit mode
audit () {
    if [ -x ${FILES} ]; then 
        ok "$FILES is exist."
	    FNRET=0
    else
        crit "$FILES is not exist."
	    FNRET=1
    fi
}

# This function will be called if the script status is on enabled mode
apply () {
    if [ $FNRET != 0 ]; then
        warn "$FILES is not exist, so need to manual check"
    else
        ok "$FILES is exist "
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
