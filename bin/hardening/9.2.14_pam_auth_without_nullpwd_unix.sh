#!/bin/bash

#
# harbian-audit for Debian GNU/Linux 7/8/9 or CentOS 8 Hardening
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

audit_debian () {
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

audit_centos () {
	for FILE in $FILES; do
        does_pattern_exist_in_file $FILE $OPTIONNAME
        if [ $FNRET = 0 ]; then
			crit "$OPTIONNAME is configured in $FILE"
			FNRET=1
		else
			ok "$OPTIONNAME is not configured in $FILE"
			FNRET=0
		fi
	done
}

# This function will be called if the script status is on enabled / audit mode
audit () {
	if [ $OS_RELEASE -eq 1 ]; then
		audit_debian	
	elif [ $OS_RELEASE -eq 2 ]; then
		audit_centos
	else
		crit "Current OS is not support!"
	fi
}

apply_debian () {
    if [ $FNRET = 0 ]; then
        ok "$PACKAGE is installed"
    elif [ $FNRET = 1 ]; then
        crit "$PACKAGE is absent, installing it"
        install_package $PACKAGE
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

apply_centos () {
	for FILE in $FILES; do
        does_pattern_exist_in_file $FILE $OPTIONNAME
        if [ $FNRET = 0 ]; then
			crit "$OPTIONNAME is configured in $FILE"
			info "Delete option $OPTIONNAME from $FILE"
			backup_file $FILE
			sed -i "s/$OPTIONNAME//" $FILE
		else
			ok "$OPTIONNAME is not configured in $FILE"
		fi
	done
}

# This function will be called if the script status is on enabled mode
apply () {
	if [ $OS_RELEASE -eq 1 ]; then
		apply_debian	
	elif [ $OS_RELEASE -eq 2 ]; then
		apply_centos
	else
		crit "Current OS is not support!"
	fi
}

# This function will check config parameters required
check_config() {
	if [ $OS_RELEASE -eq 2 ]; then
		PACKAGE='pam'
		FILES='/etc/pam.d/system-auth /etc/pam.d/password-auth'
		OPTIONNAME='nullok'
	else
		:
	fi
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
