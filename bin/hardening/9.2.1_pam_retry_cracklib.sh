#!/bin/bash

#
# harbian-audit for Debian GNU/Linux 7/8/9/10 or CentOS Hardening
#

#
# 9.2.1 Set Password Creation Requirement Parameters Using pam_cracklib: audit retry option (Scored)
# Author : Samson wen, Samson <sccxboy@gmail.com>
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=2

PACKAGE='libpam-cracklib'
PAMLIBNAME='pam_cracklib.so'
PATTERN='^password.*pam_cracklib.so'
FILE='/etc/pam.d/common-password'

# Redhat/CentOS default use pam_pwquality
PACKAGE_CENTOS='libpwquality'
PAMLIBNAME_CENTOS='pam_pwquality.so'
PATTERN_CENTOS='^password.*pam_pwquality.so'
FILE_CENTOS='/etc/pam.d/system-auth'

OPTIONNAME='retry'

# condition 
CONDT_VAL=3

# This function will be called if the script status is on enabled / audit mode
audit () {
	if [ $OS_RELEASE -eq 2 ]; then
		PACKAGE=$PACKAGE_CENTOS
		PAMLIBNAME=$PAMLIBNAME_CENTOS
		PATTERN=$PATTERN_CENTOS
		FILE=$FILE_CENTOS
	fi
    is_pkg_installed $PACKAGE
    if [ $FNRET != 0 ]; then
        crit "$PACKAGE is not installed!"
        FNRET=1
    else
        ok "$PACKAGE is installed"
        does_pattern_exist_in_file $FILE $PATTERN
        if [ $FNRET = 0 ]; then
            ok "$PATTERN is present in $FILE"
            check_param_pair_by_pam $FILE $PAMLIBNAME $OPTIONNAME le $CONDT_VAL  
            if [ $FNRET = 0 ]; then
                ok "$OPTIONNAME set condition is less than or equal to $CONDT_VAL"
            else
                crit "$OPTIONNAME set condition is greater than $CONDT_VAL"
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
	if [ $OS_RELEASE -eq 2 ]; then
		PACKAGE=$PACKAGE_CENTOS
		PAMLIBNAME=$PAMLIBNAME_CENTOS
		PATTERN=$PATTERN_CENTOS
		FILE=$FILE_CENTOS
	fi
    if [ $FNRET = 0 ]; then
        ok "$PACKAGE is installed"
    elif [ $FNRET = 1 ]; then
        crit "$PACKAGE is absent, installing it"
		if [ $OS_RELEASE -eq 2 ]; then
			yum install -y $PACKAGE
		else
			apt_install $PACKAGE
		fi
    elif [ $FNRET = 2 ]; then
        crit "$PATTERN is not present in $FILE, add default config to $FILE"
        add_line_file_before_pattern $FILE "password    requisite           pam_cracklib.so retry=3 minlen=15 difok=3" "# pam-auth-update(8) for details."
    elif [ $FNRET = 3 ]; then
        crit "$FILE is not exist, please check"
    elif [ $FNRET = 4 ]; then
        crit "$OPTIONNAME is not conf"
        add_option_to_password_check $FILE $PAMLIBNAME "$OPTIONNAME=$CONDT_VAL"
    elif [ $FNRET = 5 ]; then
        crit "$OPTIONNAME set is not match legally, reset it to $CONDT_VAL"
        reset_option_to_password_check $FILE $PAMLIBNAME "$OPTIONNAME" "$CONDT_VAL"
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
