#!/bin/bash

#
# harbian-audit for Debian GNU/Linux 11/12/Ubuntu 16~22.4 and CentOS Hardening
#

#
# 9.2.14  Must prevent the use of dictionary words for passwords: audit dictcheck option (Scored)
# Author : Samson wen, Samson <sccxboy@gmail.com>
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=2

# Redhat/CentOS default use pam_pwquality
FILE_CENTOS='/etc/security/pwquality.conf'

OPTIONNAME='dictcheck'

# condition 
CONDT_VAL=1

audit_centos () {
	check_param_pair_by_value $FILE_CENTOS $OPTIONNAME eq $CONDT_VAL  
	if [ $FNRET = 0 ]; then
		ok "Option $OPTIONNAME set condition is equal to $CONDT_VAL in $FILE_CENTOS"
	elif [ $FNRET = 1 ]; then
		crit "Option $OPTIONNAME set condition is not equal $CONDT_VAL in $FILE_CENTOS"
	elif [ $FNRET = 2 ]; then
		ok "Option $OPTIONNAME is not conf in $FILE_CENTOS, but because it default is enable, so pass"
	elif [ $FNRET = 3 ]; then
		crit "Config file $FILE_CENTOS is not exist!"
    fi
}

# This function will be called if the script status is on enabled / audit mode
audit () {
	if [ $OS_RELEASE -eq 1 ]; then
		FNRET=0
		ok "Option $OPTIONNAME is not support in Debian 7/8/9/10, so pass."
	# debian11/debian12 ubuntu 16~ default use pam_pwquality, same as centos
	elif [ $OS_RELEASE -eq 2 -o $OS_RELEASE -eq 3 -o  $OS_RELEASE -eq 11 -o $OS_RELEASE -eq 12 ]; then
		audit_centos
	else
		crit "Current OS is not support!"
		FNRET=44
	fi
}

apply_centos () {
	if [ $FNRET = 0 ]; then
		ok "$OPTIONNAME set condition is equal to $CONDT_VAL in $FILE_CENTOS"
	elif [ $FNRET = 1 ]; then
		warn "Set option $OPTIONNAME to $CONDT_VAL in $FILE_CENTOS"
		replace_in_file $FILE_CENTOS "^$OPTIONNAME.*" "$OPTIONNAME = $CONDT_VAL"
	elif [ $FNRET = 2 ]; then
		ok "Option $OPTIONNAME is not conf in $FILE_CENTOS, but because default set enable, so pass"
	elif [ $FNRET = 3 ]; then
		crit "Config file $FILE_CENTOS is not exist!"
    fi
}

# This function will be called if the script status is on enabled mode
apply () {
	if [ $OS_RELEASE -eq 1 ]; then
		ok "Option $OPTIONNAME is not support in Debian 7/8/9/10, so pass."
	# debian11/debian12 ubuntu 16~ default use pam_pwquality, same as centos
	elif [ $OS_RELEASE -eq 2 -o $OS_RELEASE -eq 3 -o  $OS_RELEASE -eq 11 -o $OS_RELEASE -eq 12 ]; then
		apply_centos
	else
		crit "Current OS is not support!"
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
