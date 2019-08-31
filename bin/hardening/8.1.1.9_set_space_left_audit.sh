#!/bin/bash

#
# harbian audit 9/10 or CentOS Hardening
#

#
# 8.1.1.9 Set space left for auditd service (Scored)
# Author : Samson wen, Samson <sccxboy@gmail.com>
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=4

FILE='/etc/audit/auditd.conf'
PATTERN='space_left'
LOGFILESYSTEM='/var/log/audit/'

# This function will be called if the script status is on enabled / audit mode
audit () {
        does_file_exist $FILE
        if [ $FNRET != 0 ]; then
            crit "$FILE does not exist"
            FNRET=1
        else
            if [ -d $LOGFILESYSTEM ]; then
                ok "$FILE exists, checking configuration"
                DISKSIZE=$(df  -B 1m $LOGFILESYSTEM | grep -v "Filesystem" | awk '{printf $2}')
                LEFTSIZE=$(bc <<<${DISKSIZE}*0.25 | awk '{print int($1)}')
                if [ $(grep "^space_left.=.*"  $FILE | awk '{printf $3}' | wc -c) -eq 0 ]; then
                    crit "$PATTERN is not configure in the $FILE."
                    FNRET=3
                else                
                    SETSIZE=$(grep "^space_left.=.*"  $FILE | awk '{printf $3}')
                    if [ "${SETSIZE}" -lt "${LEFTSIZE}" ]; then
                        crit "Space left value: ${SETSIZE} is more than audit log filesystem 25%"
                        FNRET=4
                    else
                        ok "Space left value: ${SETSIZE} is less than/equal to audit log filesystem 25%"
                        FNRET=0
                    fi
                fi
            else
                crit "$LOGFILESYSTEM is not present"
                FNRET=2
            fi
        fi
}

# This function will be called if the script status is on enabled mode
apply () {
    if [ $FNRET = 0 ]; then
        ok "$PATTERN is present in $FILE."
    elif [ $FNRET = 1 -o $FNRET = 2 ]; then
        warn "$FILE is not exist, please manual check."
    elif [ $FNRET = 3 ]; then
        warn "$PATTERN value not exist in $FILE, add it"
        DISKSIZE=$(df  -B 1m $LOGFILESYSTEM | grep -v "Filesystem" | awk '{printf $2}')
        LEFTSIZE=$(bc <<<${DISKSIZE}*0.25) | awk '{print int($1)}'
        add_end_of_file $FILE "${PATTERN} = $LEFTSIZE"
    elif [ $FNRET = 4 ]; then
        warn "$PATTERN value is incorrect in $FILE, reset it"
        DISKSIZE=$(df  -B 1m $LOGFILESYSTEM | grep -v "Filesystem" | awk '{printf $2}')
        LEFTSIZE=$(bc <<<${DISKSIZE}*0.25) | awk '{print int($1)}'
        replace_in_file $FILE "^${PATTERN}[[:space:]].*" "${PATTERN} = $LEFTSIZE"
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
