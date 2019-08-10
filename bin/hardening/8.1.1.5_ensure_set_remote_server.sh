#!/bin/bash

#
# harbian audit 9/10 or CentOS Hardening
#

#
# 8.1.1.5 Ensure set remote_server for audit service (Scored)
# Author : Samson wen, Samson <sccxboy@gmail.com>
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=4

PACKAGE='audispd-plugins'
FILE='/etc/audisp/audisp-remote.conf'
PATTERN='remote_server'

# This function will be called if the script status is on enabled / audit mode
audit () {
    is_pkg_installed $PACKAGE
    if [ $FNRET = 1 ]; then
        crit "$PACKAGE is not installed."
        FNRET=1
    else
        does_file_exist $FILE
        if [ $FNRET != 0 ]; then
            crit "$FILE does not exist"
            FNRET=2
        else
            ok "$FILE exists, checking configuration"
            VALUE=$(grep remote_server $FILE | awk -F= '{print $2}' | wc -w)
            if [ $VALUE -gt 0 ]; then
                ok "$PATTERN value is set in $FILE"
                FNRET=0
            else
                crit "$PATTERN value not set in $FILE"
                FNRET=3
            fi
        fi
    fi
}

# This function will be called if the script status is on enabled mode
apply () {
    if [ $FNRET = 0 ]; then
        ok "$PATTERN is present in $FILE"
    elif [ $FNRET = 1 ]; then
        warn "$PACKAGE is not installed, need install."
        apt_install $PACKAGE
    elif [ $FNRET = 2 ]; then
        warn "$FILE is not exist, please manual check."
    elif [ $FNRET = 3 ]; then
        warn "$PATTERN value is incorrect in $FILE, please Manual configuration"
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
