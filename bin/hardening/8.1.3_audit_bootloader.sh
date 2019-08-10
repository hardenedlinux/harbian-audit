#!/bin/bash

#
# harbian audit 7/8/9  Hardening
# Modify author:
# Samson-W (sccxboy@gmail.com)
#

#
# 8.1.3 Enable Auditing for Processes That Start Prior to auditd (Scored)
#
# todo test for centos

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=4

FILE='/etc/default/grub'
KEYWORD='GRUB_CMDLINE_LINUX'
OPTION='audit'
SETVAL=1

# This function will be called if the script status is on enabled / audit mode
audit () {
    does_file_exist $FILE
    if [ $FNRET != 0 ]; then
        crit "$FILE does not exist"
        FNRET=1
    else
        ok "$FILE exists, checking configuration"
        if [ $(grep -w "^${KEYWORD}" ${FILE} | grep -c ${OPTION}) -eq 1 ]; then 
            ok "$OPTION is present in $FILE"
            if [ $(grep -w "^${KEYWORD}" $FILE | grep -c "${OPTION}=${SETVAL}") -eq 1 ]; then
                ok "${OPTION}'s set is correctly."
                FNRET=0
            else
                crit "${OPTION}'s set is not correctly."
                FNRET=3
            fi
        else
            crit "$OPTION is not present in $FILE"
            FNRET=2
        fi 
    fi
}

# This function will be called if the script status is on enabled mode
apply () {
    if [ $FNRET = 0 ]; then
        ok "${OPTION}'s set is correctly."
    elif [ $FNRET = 1 ]; then
        warn "$FILE does not exist, creating it"
        touch $FILE
    elif [ $FNRET = 2 ]; then
        warn "$OPTION is not present in $FILE, add it to $KEYWORD line, need to reboot the system  after setting it"
        sed -i "s;\(${KEYWORD}=\)\(\".*\)\(\"\);\1\2 ${OPTION}=${SETVAL}\3;" $FILE
        /usr/sbin/update-grub2 
    elif [ $FNRET = 3 ]; then
        warn "Parameter $OPTION is present but with the wrong value -- Fixing, need to reboot the system after setting it"
        sed -i "s/${OPTION}=./${OPTION}=${SETVAL}/" $FILE 
        /usr/sbin/update-grub2
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
