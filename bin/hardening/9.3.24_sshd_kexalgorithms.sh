#!/bin/bash

#
# harbian-audit for Debian GNU/Linux 9 Hardening
#

#
# 9.3.25 Ensure only strong Key Exchange algorithms are used (Scored)
# Author : Samson wen, Samson <sccxboy@gmail.com>
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=2

PACKAGE='openssh-server'
# The only Key Exchange Algorithms currently FIPS 140-2 approved are: 
# ecdh-sha2-nistp256,ecdh-sha2-nistp384,ecdh-sha2-nistp521,diffie-hellman-group-exchange-sha256,
# diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group14-sha256

OPTIONS='KexAlgorithms=ecdh-sha2-nistp256,ecdh-sha2-nistp384,ecdh-sha2-nistp521,diffie-hellman-group-exchange-sha256,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group14-sha256'
FILE='/etc/ssh/sshd_config'

# This function will be called if the script status is on enabled / audit mode
audit () {
    is_pkg_installed $PACKAGE
    if [ $FNRET != 0 ]; then
        crit "$PACKAGE is not installed!"
		FNRET=5
	else
		SSH_PARAM=$(echo $OPTIONS | cut -d= -f 1)
		SSH_VALUES=$(echo $OPTIONS | cut -d= -f 2)
		VALUES_CHECK=$(echo $SSH_VALUES | sed 's@,@ @g')
		VALUES_RUNTIME=$(sshd -T | grep -i $SSH_PARAM | awk '{print $2}')
		SET_VALUES_TMP=""
		for VALUE in $VALUES_CHECK; do
			if [ $(echo $VALUES_RUNTIME | grep -wc $VALUE) -eq 1 ]; then
				ok "$VALUE has set in the runtime configuration."
			else
				SET_VALUES_TMP+="$VALUE"
				crit "$VALUE is not set in the runtime configuration."
			fi	
		done
		SET_VALUES=$(echo ${SET_VALUES_TMP%?})
		if [ "${SET_VALUES}Harbian" = "Harbian" ]; then
			FNRET=0
		else
			crit "Need to add set values ${SET_VALUES} to sshd_config."
			FNRET=1
		fi
	fi
}

# This function will be called if the script status is on enabled mode
apply () {
	SSH_PARAM=$(echo $OPTIONS | cut -d= -f 1)
	SSH_VALUES=$(echo $OPTIONS | cut -d= -f 2)
	case $FNRET in
		0)	ok "The value of keyword $SSH_PARAM has set to $SSH_VALUES, it's correct."
		;;
		1)	VALUES_CHECK=$(echo $SSH_VALUES | sed 's@,@ @g')
			VALUES_RUNTIME=$(sshd -T | grep -i $SSH_PARAM | awk '{print $2}')
			SET_VALUES_TMP=""
			for VALUE in $VALUES_CHECK; do
				if [ $(echo $VALUES_RUNTIME | grep -wc $VALUE) -eq 1 ]; then
					debug "$VALUE has set in the runtime configuration."
				else
					debug "$VALUE is not set in the runtime configuration."
					SET_VALUES_TMP+="$VALUE,"
				fi	
			done
			SET_VALUES=$(echo ${SET_VALUES_TMP%?})
			if [ "${SET_VALUES}Harbian" = "Harbian" ]; then
				:
			else
				warn "Need to add set values ${SET_VALUES} to sshd_config."
				PATTERN="^$SSH_PARAM[[:space:]]*"
				does_pattern_exist_in_file $FILE "$PATTERN"
				SET_VALUES_NOW="${VALUES_RUNTIME},${SET_VALUES}"
				if [ $FNRET = 0 ]; then
					warn "$SSH_PARAM has exist $FILE, replace new values $SET_VALUES_NOW to $FILE, fixing and reload"
					replace_in_file $FILE "^$SSH_PARAM[[:space:]]*.*" "$SSH_PARAM $SET_VALUES_NOW"	
					/etc/init.d/ssh reload > /dev/null 2>&1
				else
					warn "$SSH_PARAM is not present in $FILE, need add to sshd_config and reload"
					add_end_of_file $FILE "$SSH_PARAM $SET_VALUES_NOW"
					/etc/init.d/ssh reload > /dev/null 2>&1
				fi
			fi
		;;
		5)	warn "$PACKAGE is absent, installing it"
			install_package $PACKAGE
			;;
		*)	;;
	esac
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
