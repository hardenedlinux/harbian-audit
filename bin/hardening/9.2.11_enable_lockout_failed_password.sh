#!/bin/bash

#
# harbian audit 7/8/9  Hardening
#

#
# 9.2.11 Set Lockout for Failed Password Attempts (Scored)
# The number in the original document is 9.2.2
# for login and ssh service
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=3

PACKAGE='libpam-modules-bin'
AUTHPATTERN='^auth[[:space:]]*required[[:space:]]*pam_tally2.so'
AUTHFILE='/etc/pam.d/common-auth'
AUTHRULE='auth required pam_tally2.so audit silent deny=3 unlock_time=900'
ADDPATTERNLINE='# pam-auth-update(8) for details.'

# This function will be called if the script status is on enabled / audit mode
audit () {
    is_pkg_installed $PACKAGE
    if [ $FNRET != 0 ]; then
        crit "$PACKAGE is not installed!"
        FNRET=1
    else
        ok "$PACKAGE is installed"
        does_pattern_exist_in_file $AUTHFILE $AUTHPATTERN
        if [ $FNRET = 0 ]; then
                ok "$AUTHPATTERN is present in $AUTHFILE."
                FNRET=0
        else
            crit "$AUTHPATTERN is not present in $AUTHFILE"
            FNRET=2
        fi
    fi
}

# This function will be called if the script status is on enabled mode
apply () {
    if [ $FNRET = 0 ]; then
        ok "installed"
    elif [ $FNRET = 1 ]; then
        warn "Apply:$PACKAGE is absent, installing it"
        apt_install $PACKAGE
    elif [ $FNRET = 2 ]; then
        warn "Apply:$AUTHPATTERN is not present in $AUTHFILE"
        add_line_file_after_pattern "$AUTHFILE" "$AUTHRULE" "$ADDPATTERNLINE"
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
