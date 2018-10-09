#!/bin/bash

#
# harbian audit 9  Hardening
#

#
# 10.1.9 Set how many seconds to wait to allow login when the last login failed (Scored)
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=3

PACKAGE='login'
OPTIONS='FAIL_DELAY=4'
FILE='/etc/login.defs'

# This function will be called if the script status is on enabled / audit mode
audit () {
    is_pkg_installed $PACKAGE
    if [ $FNRET != 0 ]; then
        crit "$PACKAGE is not installed!"
        FNRET=1
    else
        ok "$PACKAGE is installed"
        for SSH_OPTION in $OPTIONS; do
            SSH_PARAM=$(echo $SSH_OPTION | cut -d= -f 1)
            SSH_VALUE=$(echo $SSH_OPTION | cut -d= -f 2)
            PATTERN="^$SSH_PARAM[[:space:]]*"
            does_pattern_exist_in_file $FILE "$PATTERN"
            if [ $FNRET = 0 ]; then
                ok "$PATTERN is present in $FILE"
                if [ $(sed -e '/^#/d' -e '/^[ \t][ \t]*#/d' -e 's/#.*$//' -e '/^$/d' /etc/login.defs  | grep FAIL_DELAY | awk '{print $2}') -lt $SSH_VALUE ]; then
                    crit "$SSH_PARAM value is less than $SSH_VALUE"
                    FNRET=3
                else
                    ok "$SSH_PARAM value is equal or greater to  $SSH_VALUE"
                    FNRET=0
                fi
            else
                crit "$PATTERN is not present in $FILE"
                FNRET=2
            fi
        done
    fi
}

# This function will be called if the script status is on enabled mode
apply () {
    SSH_PARAM=$(echo $SSH_OPTION | cut -d= -f 1)
    SSH_VALUE=$(echo $SSH_OPTION | cut -d= -f 2)
    if [ $FNRET = 0 ]; then
        ok "FAIL_DELAY is set"
    elif [ $FNRET = 1 ]; then
        crit "$PACKAGE is absent, installing it"
        apt_install $PACKAGE
    elif [ $FNRET = 2 ]; then
        warn "$SSH_PARAM is not present in $FILE, adding it"
        add_end_of_file $FILE "$SSH_PARAM $SSH_VALUE"
    elif [ $FNRET = 3 ]; then
        info "Parameter $SSH_PARAM is present but with the wrong value -- Fixing"
        replace_in_file $FILE "^$SSH_PARAM[[:space:]]*.*" "$SSH_PARAM $SSH_VALUE"
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
