#!/bin/bash

#
# harbian audit 7/8/9  Hardening
#

#
# 10.1.6 Set maximum password lifetime (Scored)
# Authors : Samson wen, Samson <sccxboy@gmail.com>
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=3

#set 60 day
LIFETIME=60
FILE='/etc/shadow'

# This function will be called if the script status is on enabled / audit mode
audit () 
{
    if [ $(awk -F: '$5 != "'$LIFETIME'" {print $1}' $FILE | wc -l) -gt 0 ]; then
        crit "Have least user's maxinum password lifttime is not equal $LIFETIME days"
        FNRET=1
    else
        ok "All user's maxinum password lifttime is $LIFETIME days"
        FNRET=0
    fi
}

# This function will be called if the script status is on enabled mode
apply () {
    if [ $FNRET = 0 ]; then
        ok "All user's maxinum password lifttime is $LIFETIME days"
    elif [ $FNRET = 1 ]; then
        info "Set all user's maxinum password lifetime to $LIFETIME"
        for USERNAME in $(awk -F: '$5 != "'$LIFETIME'" {print $1}' $FILE); 
        do 
            chage -M $LIFETIME $USERNAME
        done
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
