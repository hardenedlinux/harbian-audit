#!/bin/bash

#
# harbian-audit for Debian GNU/Linux 7/8/9  Hardening
#

#
# 9.3.6 Set SSH IgnoreRhosts to Yes (Scored)
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=2

PACKAGE='openssh-server'
OPTIONS='IgnoreRhosts=yes'
FILE='/etc/ssh/sshd_config'

# This function will be called if the script status is on enabled / audit mode
audit () {
    is_pkg_installed $PACKAGE
    if [ $FNRET != 0 ]; then
        crit "$PACKAGE is not installed!"
		FNRET=5
	else
		ok "$PACKAGE is installed"
		SSH_PARAM=$(echo $OPTIONS | cut -d= -f 1)
		SSH_VALUE=$(echo $OPTIONS | cut -d= -f 2)
		check_sshd_conf_for_one_value_runtime $SSH_PARAM $SSH_VALUE
		if [ $FNRET = 0 ]; then 
			ok "The value of keyword $SSH_PARAM has set to $SSH_VALUE, it's correct."
			FNRET=0
		else
			crit "The keyword value pair "\"$SSH_PARAM $SSH_VALUE\"" does not exist in the sshd runtime configuration."
			PATTERN="^$SSH_PARAM[[:space:]]*"
			PATTERN_INFO="$SSH_PARAM $SSH_VALUE"
			does_pattern_exist_in_file $FILE "$PATTERN"
			if [ $FNRET = 0 ]; then
				crit "The value of keyword $SSH_PARAM is not set to $SSH_VALUE, it's incorrect."
				FNRET=1
			else
				crit "$PATTERN_INFO is not present in $FILE"
				FNRET=2
			fi
		fi
	fi
}

# This function will be called if the script status is on enabled mode
apply () {
	SSH_PARAM=$(echo $OPTIONS | cut -d= -f 1)
	SSH_VALUE=$(echo $OPTIONS | cut -d= -f 2)
	PATTERN_INFO="$SSH_PARAM $SSH_VALUE"
	case $FNRET in
		0)	ok "The value of keyword $SSH_PARAM has set to $SSH_VALUE, it's correct."
			;;
		1)	warn "The value of keyword $SSH_PARAM is not set to $SSH_VALUE, it's incorrect. Fixing and reload config"
			replace_in_file $FILE "^$SSH_PARAM[[:space:]]*.*" "$SSH_PARAM $SSH_VALUE"
			/etc/init.d/ssh reload > /dev/null 2>&1
			;;
		2)	warn "$PATTERN_INFO is not present in $FILE, need add to sshd_config and reload"
			add_end_of_file $FILE "$SSH_PARAM $SSH_VALUE"
			/etc/init.d/ssh reload > /dev/null 2>&1
			;;
		5)	warn "$PACKAGE is absent, installing it"
			apt_install $PACKAGE
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
