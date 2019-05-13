#!/bin/bash

#
# harbian audit 7/8/9  Hardening
#

#
# 10.1.10 Set maxlogins for all accounts  (Scored)
# Author : Samson wen, Samson <sccxboy@gmail.com>
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=2

PACKAGE='libpam-modules'
OPTIONS='maxsyslogins'
OPVALUE=10
FILE='/etc/security/limits.conf'

# This function will be called if the script status is on enabled / audit mode
audit () {
    is_pkg_installed $PACKAGE
    if [ $FNRET != 0 ]; then
        crit "$PACKAGE is not installed!"
        FNRET=1
    else
        ok "$PACKAGE is installed"
        does_file_exist $FILE
        if [ $FNRET != 0 ]; then                    
            crit "$FILE does not exist"
            FNRET=2
        else
            ok "$FILE does exist"
            COUNT=$(sed -e '/^#/d' -e '/^[ \t][ \t]*#/d' -e 's/#.*$//' -e '/^$/d' $FILE | grep "${OPTIONS}" | wc -l)
            if [ $COUNT -gt 0 ]; then
                ok "$OPTIONS is set in $FILE."
                VALUE=$(sed -e '/^#/d' -e '/^[ \t][ \t]*#/d' -e 's/#.*$//' -e '/^$/d' $FILE | grep ".*[[:space:]].*${OPTIONS}[[:space:]].*${OPVALUE}" | wc -l)
                if [ $VALUE -eq 0 ]; then
                    crit "$OPTIONS value is incorrect in $FILE"
                    FNRET=4
                else
                    ok "$OPTIONS value is correct in $FILE"
                    FNRET=0
                fi
            else
                crit "$OPTIONS is not set in $FILE."
                FNRET=3
            fi
        fi

    fi
}

# This function will be called if the script status is on enabled mode
apply () {
    if [ $FNRET = 0 ]; then
        ok "$PACKAGE is installed"
    elif [ $FNRET = 1 ]; then
        warn "$PACKAGE is not installed, need install."
        apt_install $PACKAGE
    elif [ $FNRET = 2 ]; then
        warn "$FILE is not exist, need manual check."
    elif [ $FNRET = 3 ]; then
        warn "$OPTIONS value not exist in $FILE, add it"
        add_end_of_file $FILE "* hard ${OPTIONS}  $OPVALUE"
    elif [ $FNRET = 4 ]; then
        warn "$OPTIONS value is incorrect in $FILE, reset it"
        replace_in_file $FILE "^[^#].*${OPTIONS}[[:space:]].*" "\* hard ${OPTIONS}  $OPVALUE"
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
