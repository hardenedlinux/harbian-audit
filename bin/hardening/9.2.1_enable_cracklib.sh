#!/bin/bash

#
# harbian audit 7/8/9  Hardening
#

#
# 9.2.1 Set Password Creation Requirement Parameters Using pam_cracklib (Scored)
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=2

PACKAGE='libpam-cracklib'
PAMLIBNAME='pam_cracklib.so'
PATTERN='^password.*pam_cracklib.so'
FILE='/etc/pam.d/common-password'

OPTION_RETRY='retry'
OPTION_MINLEN='minlen'
OPTION_DCREDIT='dcredit'
OPTION_UCREDIT='ucredit'
OPTION_OCREDIT='ocredit'
OPTION_LCREDIT='lcredit'
OPTION_DIFOK='difok'
OPTION_MINCLASS='minclass'
OPTION_MAXREPEAT='maxrepeat'
OPTION_MAXCLASSREPEAT='maxclassrepeat'

# condition 
RETRY_CONDT=3
MINLEN_CONDT=14
DCREDIT_CONDT=-1
UCREDIT_CONDT=-1
OCUEDIT_CONDT=-1
LCREDIT_CONDT=-1
DIFOK_CONDT=8
MINCLASS_CONDT=4
MAXREPEAT=3
MAXCLASSREPEAT_CONDT=4

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
            #ok "$PATTERN is present in $FILE"
            #check_password_by_pam $OPTION_DCREDIT gt $DCREDIT_CONDT  
            #if [ $FNRET = 0 ]; then
            #    ok "$OPTION_DCREDIT set condition is $DCREDIT_CONDT"
            #else
            #    crit "$OPTION_DCREDIT set condition is $DCREDIT_CONDT"
            #    FNRET=1
            #fi
            ok "$PATTERN is present in $FILE"
            check_password_by_pam $OPTION_RETRY eq $RETRY_CONDT  
            if [ $FNRET = 0 ]; then
                ok "$OPTION_RETRY set condition is $RETRY_CONDT"
            else
                crit "$OPTION_RETRY set condition is $RETRY_CONDT"
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
#    is_pkg_installed $PACKAGE
    if [ $FNRET = 0 ]; then
        ok "$PACKAGE is installed"
    elif [ $FNRET = 1 ]; then
        crit "$PACKAGE is absent, installing it"
        apt_install $PACKAGE
    elif [ $FNRET = 2 ]; then
        crit "$PATTERN is not present in $FILE, add default config to $FILE"
        add_line_file_before_pattern $FILE "password    requisite           pam_cracklib.so retry=3 minlen=8 difok=3" "# pam-auth-update(8) for details."
    elif [ $FNRET = 3 ]; then
        crit "$FILE is not exist, please check"
    elif [ $FNRET = 4 ]; then
        crit "$OPTION_RETRY is not conf"
        add_option_to_password_check $FILE $PAMLIBNAME "$OPTION_RETRY=$RETRY_CONDT"
    elif [ $FNRET = 5 ]; then
        crit "$OPTION_RETRY set is not match legally, reset it to $RETRY_CONDT"
        reset_option_to_password_check $FILE $PAMLIBNAME "$OPTION_RETRY" "$RETRY_CONDT"
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
