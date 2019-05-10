#!/bin/bash

#
# harbian audit 7/8/9  Hardening
#

#
# 9.2.14 Configure password without blank or null passwords (Scored)
# Author : Samson wen, Samson <sccxboy@gmail.com>
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=3

PACKAGE='libpam-modules'
PATTERN='^auth.*pam_unix.so'
FILE='/etc/pam.d/common-auth'
KEYWORD='pam_unix.so'
OPTIONNAME1='nullok'
OPTIONNAME2='nullok_secure'

# This function will be called if the script status is on enabled / audit mode
audit () {
    is_pkg_installed $PACKAGE
    if [ $FNRET != 0 ]; then
        crit "$PACKAGE is not installed!"
        FNRET=1
    else
        ok "$PACKAGE is installed"
        does_pattern_exist_in_file $FILE $PATTERN
        if [ $FNRET = 0 ]; then
            ok "$PATTERN is present in $FILE"
            check_auth_option_nullok_by_pam $KEYWORD $OPTIONNAME1 $OPTIONNAME2
            if [ $FNRET = 0 ]; then
                ok "$OPTIONNAME1 is not configured"
            elif [ $FNRET = 4 ]; then
                crit "$OPTIONNAME1 is  configured"
            elif [ $FNRET = 5 ]; then
                crit "$OPTIONNAME2 is  configured"
            fi
        else
            crit "$PATTERN is not present in $FILE"
            FNRET=2
        fi
    fi
}

# This function will be called if the script status is on enabled mode
apply () {
    if [ $FNRET = 0 ]; then
        ok "$PACKAGE is installed"
    elif [ $FNRET = 1 ]; then
        crit "$PACKAGE is absent, installing it"
        apt_install $PACKAGE
    elif [ $FNRET = 2 ]; then
        ok "$PATTERN is not present in $FILE, not need add"
    elif [ $FNRET = 3 ]; then
        crit "$FILE is not exist, please check"
    elif [ $FNRET = 4 ]; then
        info "Delete option $OPTIONNAME1 from $FILE"
        sed -i "s/$OPTIONNAME1//" $FILE
    elif [ $FNRET = 5 ]; then
        info "Delete option $OPTIONNAME2 from $FILE"
        sed -i "s/$OPTIONNAME2//" $FILE
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
