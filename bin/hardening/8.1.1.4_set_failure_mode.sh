#!/bin/bash

#
# harbian audit 9/10 or CentOS Hardening
#

#
# 8.1.1.4 Set failure mode of audit service (Scored)
# Author : Samson wen, Samson <sccxboy@gmail.com>
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=4

FILE='/etc/audit/rules.d/audit.rules'
PATTERN='failure'
SETVALUE=2

# This function will be called if the script status is on enabled / audit mode
audit () {
    does_file_exist $FILE
    if [ $FNRET != 0 ]; then
        crit "$FILE does not exist"
        FNRET=1
    else
        ok "$FILE exists, checking configuration"
        VALUE=$(auditctl -s | grep failure | awk '{print $2}')
        if [ $VALUE -ge 1 -a $VALUE -le 2 ]; then
            ok "$PATTERN value is ok in $FILE"
            FNRET=0
        else
            crit "$PATTERN value is incorrect in $FILE"
            FNRET=2
        fi
    fi
}

# This function will be called if the script status is on enabled mode
apply () {
    if [ $FNRET = 0 ]; then
        ok "$PATTERN is present in $FILE"
    elif [ $FNRET = 1 ]; then
        warn "$FILE does not exist, creating it"
        touch $FILE
        LINENUM=$(grep '^[^#]' $FILE -n | awk -F: 'NR==1{print $1}')
        sed -i "${LINENUM}a -f $SETVALUE" $FILE
    elif [ $FNRET = 2 ]; then
        warn "$PATTERN value is incorrect in $FILE, reset it"
        replace_in_file $FILE "^-f[[:space:]]*.*" "-f $SETVALUE"
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
