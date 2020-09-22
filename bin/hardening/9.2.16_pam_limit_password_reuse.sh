#!/bin/bash

#
# harbian-audit for Debian GNU/Linux 7/8/9 or CentOS 8 Hardening
#

#
# 9.2.16 Limit Password Reuse (Scored)
# The number in the original document is 9.2.3
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=3

PACKAGE='libpam-modules'
PATTERN='^password.*pam_pwhistory.so'
FILES='/etc/pam.d/common-password'
KEYWORD='pam_pwhistory.so'
ADDPATTERNLINE='# pam-auth-update(8) for details.'
AUTHRULE='password required pam_pwhistory.so remember=5'
OPTIONNAME='remember'
CONDT_VAL=5

# This function will be called if the script status is on enabled / audit mode
audit () {
    is_pkg_installed $PACKAGE
    if [ $FNRET != 0 ]; then
        crit "$PACKAGE is not installed!"
        FNRET=1
    else
        ok "$PACKAGE is installed"
		for FILE in $FILES; do
        	does_pattern_exist_in_file $FILE $PATTERN
        	if [ $FNRET = 0 ]; then
            	ok "$PATTERN is present in $FILE"
            	check_param_pair_by_pam $FILE $KEYWORD $OPTIONNAME ge $CONDT_VAL
            	if [ $FNRET = 0 ]; then
					ok "$OPTIONNAME set condition is greater-than-or-equal-to $CONDT_VAL"
					reset_ok
					return
            	else
                	crit "$OPTIONNAME set condition is not greater-than-or-equal-to $CONDT_VAL"
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
    if [ $FNRET = 0 ]; then
		ok "$OPTIONNAME set condition is greater-than-or-equal-to $CONDT_VAL"
    elif [ $FNRET = 1 ]; then
        crit "$PACKAGE is absent, installing it"
        install_package $PACKAGE
    elif [ $FNRET = 2 ]; then
		if [ $OS_RELEASE -eq 2 ]; then
			add_line_file_after_pattern_lastline  "$FILE" "$AUTHRULE" "$ADDPATTERNLINE"
		else
			add_line_file_before_pattern $FILE "$AUTHRULE" "$ADDPATTERNLINE"
		fi
    elif [ $FNRET = 3 ]; then
        crit "$FILE is not exist, please check"
    elif [ $FNRET = 4 ]; then
        crit "$OPTIONNAME is not conf in $FILE"
        add_option_to_password_check $FILE $KEYWORD "$OPTIONNAME=$CONDT_VAL"
    elif [ $FNRET = 5 ]; then
        reset_option_to_password_check $FILE $KEYWORD $OPTIONNAME $CONDT_VAL 
		crit "$OPTIONNAME set is not greater-than-or-equal-to $CONDT_VAL, reset it to $CONDT_VAL"
    fi 
}

# This function will check config parameters required
check_config() {
	if [ $OS_RELEASE -eq 2 ]; then  
		PACKAGE='pam'
		FILES='/etc/pam.d/system-auth /etc/pam.d/password-auth'
		AUTHRULE='password    requisite     pam_pwhistory.so use_authtok remember=5 retry=3'
		ADDPATTERNLINE='password[[:space:]]*requisite'
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
