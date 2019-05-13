#!/bin/bash

#
# harbian audit 7/8/9  Hardening
#

#
# 10.1.11 Ensure no shosts configure file on system (Scored)
# Author : Samson wen, Samson <sccxboy@gmail.com>
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=3

FILENAME='.shosts'
FILENAME1='shosts.equiv'

# This function will be called if the script status is on enabled / audit mode
audit () {
    COUNT=$(find / -name "${FILENAME}" | wc -l)
    COUNT1=$(find / -name "${FILENAME1}" | wc -l)
    if [ "$COUNT" -ne 0 -o "$COUNT1" -ne 0 ]; then
        crit "$FILENAME or $FILENAME1 file is exist on system."
        FNRET=1
    else
        ok "$FILENAME and $FILENAME1 file is not on system."
        FNRET=0
    fi
}

# This function will be called if the script status is on enabled mode
apply () {
    if [ $FNRET = 0 ]; then
        ok "$FILENAME and $FILENAME1 file is not on system."
    elif [ $FNRET = 1 ]; then
        warn "$FILENAME or $FILENAME1 file is exist on the system, delete all like this name file on the system."
        find / -name "$FILENAME" -exec rm {} \;
        find / -name "$FILENAME1" -exec rm {} \;
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
