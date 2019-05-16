#!/bin/bash

#
# harbian audit 7/8/9  Hardening
#

#
# 9.2.13 Set password with the SHA512 algorithm (Scored)
# Author : Samson wen, Samson <sccxboy@gmail.com>
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=3

PACKAGE='libpam-modules'
PATTERN='^password.*pam_unix.so'
FILE='/etc/pam.d/common-password'
KEYWORD='pam_unix.so'
OPTIONNAME='sha512'
ROUNDS_KEY='rounds'
ROUNDS_V='5000'

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
            check_no_param_option_by_pam $KEYWORD $OPTIONNAME $FILE
            if [ $FNRET = 0 ]; then
                ok "$OPTIONNAME is already configured"
            else
                crit "$OPTIONNAME is not configured"
            fi
            check_param_pair_by_pam $FILE $KEYWORD $ROUNDS_KEY ge $ROUNDS_V 
            if [ $FNRET = 0 ]; then
                ok "$ROUNDS_KEY set condition is $ROUNDS_V"
            else
                crit "$ROUNDS_KEY set is not match legally, $ROUNDS_KEY is set $ROUNDS_V"
                #FNRET=3
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
        warn "$PATTERN is not present in $FILE"
        add_line_file_before_pattern $FILE "password [success=1 default=ignore] pam_unix.so obscure sha512 rounds=5000" "# pam-auth-update(8) for details."
    fi
	check_no_param_option_by_pam $KEYWORD $OPTIONNAME $FILE
    if [ $FNRET = 3 ]; then
        crit "$FILE is not exist, please check"
    elif [ $FNRET = 4 ]; then
        crit "$OPTIONNAME is not conf in $FILE"
        add_option_to_password_check $FILE $KEYWORD $OPTIONNAME
    fi 
	check_param_pair_by_pam $FILE $KEYWORD $ROUNDS_KEY ge $ROUNDS_V 
    if [ $FNRET = 3 ]; then
        crit "$FILE is not exist, please check"
    elif [ $FNRET = 4 ]; then
        crit "$ROUNDS_KEY is not conf"
        add_option_to_password_check $FILE $KEYWORD "$ROUNDS_KEY=$ROUNDS_V"
    elif [ $FNRET = 5 ]; then
        crit "$ROUNDS_KEY set is not match legally, reset it to $ROUNDS_V"
        reset_option_to_password_check $FILE $KEYWORD "$ROUNDS_KEY" "$ROUNDS_V"
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
