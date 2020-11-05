#!/bin/bash

#
# harbian-audit for Debian GNU/Linux 7/8/9  Hardening
#

#
# 9.3.12 Set Idle Timeout Interval for User Login (Scored)
# Modify by: Samson-W (sccxboy@gmail.com)
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=3

PACKAGE='openssh-server'
FILE='/etc/ssh/sshd_config'

# This function will be called if the script status is on enabled / audit mode
audit () {
    OPTIONS="ClientAliveInterval=$SSHD_TIMEOUT ClientAliveCountMax=0"
    is_pkg_installed $PACKAGE
    if [ $FNRET != 0 ]; then
        crit "$PACKAGE is not installed!"
		FNRET=5
    else
        ok "$PACKAGE is installed"
        for SSH_OPTION in $OPTIONS; do
			SSH_PARAM=$(echo $SSH_OPTION | cut -d= -f 1)
			SSH_VALUE=$(echo $SSH_OPTION | cut -d= -f 2)
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
        done
    fi
}

# This function will be called if the script status is on enabled mode
apply () {
    OPTIONS="ClientAliveInterval=$SSHD_TIMEOUT ClientAliveCountMax=0"
    if [ $FNRET = 5 ]; then
        warn "$PACKAGE is absent, installing it"
       	install_package $PACKAGE
	else 
		:
    fi
    for SSH_OPTION in $OPTIONS; do
		SSH_PARAM=$(echo $SSH_OPTION | cut -d= -f 1)
		SSH_VALUE=$(echo $SSH_OPTION | cut -d= -f 2)
		check_sshd_conf_for_one_value_runtime $SSH_PARAM $SSH_VALUE
		if [ $FNRET = 0 ]; then 
			ok "The value of keyword $SSH_PARAM has set to $SSH_VALUE, it's correct."
		else
			warn "The keyword value pair "\"$SSH_PARAM $SSH_VALUE\"" does not exist in the sshd runtime configuration."
			PATTERN="^$SSH_PARAM[[:space:]]*"
			PATTERN_INFO="$SSH_PARAM $SSH_VALUE"
			does_pattern_exist_in_file $FILE "$PATTERN"
			if [ $FNRET = 0 ]; then
				warn "The value of keyword $SSH_PARAM is not set to $SSH_VALUE, it's incorrect. Fixing and reload config"
				replace_in_file $FILE "^$SSH_PARAM[[:space:]]*.*" "$SSH_PARAM $SSH_VALUE"
				/etc/init.d/ssh reload > /dev/null 2>&1
			else
				warn "$PATTERN_INFO is not present in $FILE, need add to sshd_config and reload"
				add_end_of_file $FILE "$SSH_PARAM $SSH_VALUE"
				/etc/init.d/ssh reload > /dev/null 2>&1
			fi	
		fi
	done
}

# This function will create the config file for this check with default values
create_config() {
    cat <<EOF
status=disabled
# In seconds, value of ClientAliveInterval, ClientAliveCountMax bedoing set to 0
# Settles sshd idle timeout
SSHD_TIMEOUT=300
EOF
}

# This function will check config parameters required
check_config() {
    if [ -z $SSHD_TIMEOUT ]; then
        crit "SSHD_TIMEOUT is not set, please edit configuration file"
        exit 128
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
