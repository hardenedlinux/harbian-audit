#!/bin/bash

#
# harbian audit 7/8/9  Hardening
#

#
# 10.1.5 Set mininum password lifetim (Scored)
# Authors : Samson wen, Samson <sccxboy@gmail.com>
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=3

#set 1 day
LIFETIME=1
FILE='/etc/shadow'

# This function will be called if the script status is on enabled / audit mode
audit () 
{
    if [ $(awk -F: '$4 != "'$LIFETIME'" {print $1}' $FILE | wc -l) -gt 0 ]; then
        crit "Have least user's mininum password lifttime is not equal $LIFETIME day"
        FNRET=1
    else
        ok "All user's mininum password lifttime is $LIFETIME day"
        FNRET=0
    fi
}

# This function will be called if the script status is on enabled mode
apply () {
    if [ $FNRET = 0 ]; then
        ok "All user's mininum password lifttime is $LIFETIME day"
    elif [ $FNRET = 1 ]; then
        info "Set all user's mininum password lifetime to $LIFETIME"
        for USERNAME in $(awk -F: '$4 != "'$LIFETIME'" {print $1}' $FILE); 
        do 
            chage -m $LIFETIME $USERNAME
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
