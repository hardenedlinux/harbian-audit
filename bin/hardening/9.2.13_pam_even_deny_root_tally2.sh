#!/bin/bash

#
# harbian-audit for Debian GNU/Linux 9 or CentOS 8 Hardening
#

#
# 9.2.13 Ensure unsuccessful root logon occur the associated account must be locked. (Scored)
# Replaced pam_tally2 with pam_faillock in debian 11
# Author : Samson wen, Samson <sccxboy@gmail.com>
# for login and ssh service
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=3

PACKAGE='libpam-modules-bin'
AUTHFILE='/etc/pam.d/common-auth'
ADDPATTERNLINE='# pam-auth-update(8) for details.'
DENYROOT='even_deny_root'

# This function will be called if the script status is on enabled / audit mode
audit_before11 () {
    is_pkg_installed $PACKAGE
    if [ $FNRET != 0 ]; then
        crit "$PACKAGE is not installed!"
        FNRET=1
    else
        ok "$PACKAGE is installed"
        does_pattern_exist_in_file $AUTHFILE $AUTHPATTERN
        if [ $FNRET = 0 ]; then
                ok "$AUTHPATTERN is present in $AUTHFILE."
                check_no_param_option_by_pam $PAMLIBNAME $DENYROOT $AUTHFILE
                if [ $FNRET = 0 ]; then
                    ok "$DENYROOT is already configured"
                else
                    crit "$DENYROOT is not present in $AUTHFILE"
                fi
        else
            crit "$AUTHPATTERN is not present in $AUTHFILE"
            FNRET=2
        fi
    fi
}

audit_debian11 () {
    is_pkg_installed $PACKAGE
    if [ $FNRET != 0 ]; then
        crit "$PACKAGE is not installed!"
        FNRET=11
    else
        ok "$PACKAGE is installed"
        does_pattern_exist_in_file $AUTHFILE $AUTHPATTERN
        if [ $FNRET = 0 ]; then
                ok "$AUTHPATTERN is present in $AUTHFILE."
		check_no_param_option_by_value $SECCONFFILE $DENYROOT
		if [ $FNRET = 0 ]; then
			ok "Option $DENYROOT is conf in $SECCONFFILE"
		elif [ $FNRET = 1 ]; then
			crit "Config file $SECCONFFILE is not exist!"
		elif [ $FNRET = 2 ]; then
			crit "Option $DENYROOT is not conf in $SECCONFFILE"
    		fi
	else
            crit "$AUTHPATTERN is not present in $AUTHFILE"
            FNRET=12
	fi
    fi
}

audit () {
	if [ $ISDEBIAN11 = 1 ]; then
		audit_debian11
	else
		audit_before11
	fi
}

apply_before11 () {
    if [ $FNRET = 0 ]; then
		ok "$DENYROOT is already configured"
    elif [ $FNRET = 1 ]; then
        warn "Apply:$PACKAGE is absent, installing it"
        install_package $PACKAGE
    elif [ $FNRET = 2 ]; then
        warn "Apply:$AUTHPATTERN is not present in $AUTHFILE"
		if [ $OS_RELEASE -eq 2 ]; then
			add_line_file_after_pattern_lastline "$AUTHFILE" "$AUTHRULE" "$ADDPATTERNLINE"
		else
        	add_line_file_after_pattern "$AUTHFILE" "$AUTHRULE" "$ADDPATTERNLINE"
		fi
    elif [ $FNRET = 3 ]; then
        crit "$AUTHFILE is not exist, please check"
    elif [ $FNRET = 4 ]; then
        warn "Apply:$DENYROOT is not conf"   
        add_option_to_auth_check $AUTHFILE $PAMLIBNAME $DENYROOT
    fi
}

# Input: 
# Param1: return-value of call check_no_param_option_by_value
# Function: Perform corresponding repair actions based on the return value of the error. 
apply_secconffile() {
	FNRET=$1
	if [ $FNRET = 0 ]; then
		ok "Option $DENYROOT is conf in $SECCONFFILE"
	elif [ $FNRET = 1 ]; then
		warn "Config file $SECCONFFILE is not exist! Please check it by youself"
	elif [ $FNRET = 2 ]; then
		warn "Option $DENYROOT is not conf in $SECCONFFILE, add it "
		add_end_of_file $SECCONFFILE "$DENYROOT"
	else
		warn "This param $FNRET was not defined!!!"
	fi
}

apply_debian11 () {
	if [ $FNRET = 0 ]; then
		ok "Option $DENYROOT is conf in $SECCONFFILE"
    elif [ $FNRET = 11 ]; then
        warn "Apply:$PACKAGE is absent, installing it"
        install_package $PACKAGE
        does_pattern_exist_in_file $AUTHFILE $AUTHPATTERN
        if [ $FNRET != 0 ]; then
			add_line_file_after_pattern "$AUTHFILE" "$AUTHRULE" "$ADDPATTERNLINE"
			check_no_param_option_by_value $SECCONFFILE $DENYROOT
			apply_secconffile $FNRET
		fi
    elif [ $FNRET = 12 ]; then
		add_line_file_after_pattern "$AUTHFILE" "$AUTHRULE" "$ADDPATTERNLINE"
		check_no_param_option_by_value $SECCONFFILE $DENYROOT
		apply_secconffile $FNRET
	else
		apply_secconffile $FNRET
	fi
}

# This function will be called if the script status is on enabled mode
apply () {
	if [ $ISDEBIAN11 = 1 ]; then
		apply_debian11
	else
		apply_before11
	fi
}

# This function will check config parameters required
check_config() {
	if [ $OS_RELEASE -eq 2 ]; then
		PACKAGE='pam'
		PAMLIBNAME='pam_faillock.so'
		AUTHPATTERN='^auth[[:space:]]*required[[:space:]]*pam_faillock.so'
		AUTHFILE='/etc/pam.d/password-auth'
		AUTHRULE='auth    required pam_faillock.so preauth silent audit deny=3 even_deny_root fail_interval=900 unlock_time=900'
		ADDPATTERNLINE='auth[[:space:]]*required'
		DENYROOT='even_deny_root'
	else
		is_debian_11
		# faillock for Debian 11 
                if [ $FNRET = 0 ]; then
			ISDEBIAN11=1
			SECCONFFILE='/etc/security/faillock.conf'
			AUTHPATTERN='^auth[[:space:]]*required[[:space:]]*pam_faillock.so'
			AUTHRULE='auth    required pam_faillock.so'
		else
			ISDEBIAN11=0
			PAMLIBNAME='pam_tally2.so'
			AUTHPATTERN='^auth[[:space:]]*required[[:space:]]*pam_tally2.so'
			AUTHRULE='auth    required pam_tally2.so deny=3 even_deny_root unlock_time=900'
		fi
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
