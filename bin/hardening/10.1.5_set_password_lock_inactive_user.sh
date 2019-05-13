#!/bin/bash

#
# harbian audit 7/8/9  Hardening
#

#
# 10.1.5 Ensure inactive password lock is 30 days or less (Scored)
# Author: Samson-W (sccxboy@gmail.com)
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=3

OPTIONS='INACTIVE=30'
SHA_FILE='/etc/shadow'
DISABLE_V='-1'
FILE='/etc/default/useradd'

# This function will be called if the script status is on enabled / audit mode
audit () {
		SSH_PARAM=$(echo $OPTIONS | cut -d= -f 1)
		SSH_VALUE=$(echo $OPTIONS | cut -d= -f 2)
		INACTIVE_V=$(useradd -D | grep $SSH_PARAM | awk -F= '{print $2}')
		if [ $INACTIVE_V -eq $DISABLE_V ]; then
			crit "INACTIVE feature has disabled."
		elif [ $INACTIVE_V -eq 0 ]; then
			crit "INACTIVE value has disabled."
		elif [ $INACTIVE_V -gt $SSH_VALUE ]; then
			crit "INACTIVE value is greater than $SSH_VALUE day"
		else
			ok "All user's INACTIVE value is equal or less than $SSH_VALUE day"
		fi

		if [ $(egrep ^[^:]+:[^\!*] $SHA_FILE | awk -F: '{print $7}' | wc -w) -eq 0 ]; then
			crit "Have least user's INACTIVE password lifttime is not set"
		else
			if [ $(egrep ^[^:]+:[^\!*] $SHA_FILE | awk -F: '$7 > "'$SSH_VALUE'" {print $1}' | wc -l) -gt 0 ]; then
				crit "Have least user's INACTIVE password lifttime is greater than $SSH_VALUE day"
			else
				ok "All user's INACTIVE password lifttime is equal or less than $SSH_VALUE day"
			fi
		fi
}

# This function will be called if the script status is on enabled mode
apply () {
	SSH_PARAM=$(echo $OPTIONS | cut -d= -f 1)
	SSH_VALUE=$(echo $OPTIONS | cut -d= -f 2)
	PATTERN="^$SSH_PARAM=$SSH_VALUE"
	does_pattern_exist_in_file $FILE "$PATTERN"
	if [ $FNRET = 0 ]; then
		ok "$PATTERN is present in $FILE"
	else
		warn "$PATTERN is not present in $FILE, adding it"
		does_pattern_exist_in_file $FILE "^$SSH_PARAM"
		if [ $FNRET != 0 ]; then
			add_end_of_file $FILE "$SSH_PARAM=$SSH_VALUE"
		else
			info "Parameter $SSH_PARAM is present but with the wrong value -- Fixing"
			replace_in_file $FILE "^$SSH_PARAM.*" "$SSH_PARAM=$SSH_VALUE"
		fi
	fi
	if [ $(egrep ^[^:]+:[^\!*] $SHA_FILE | awk -F: '{print $7}' | wc -w) -eq 0 ]; then
		warn "Have least user's INACTIVE password lifttime is not set. Fixing"
		for USERNAME in $(egrep ^[^:]+:[^\!*] $SHA_FILE | awk -F: '{print $1}'); 
		do 
			chage --inactive $SSH_VALUE $USERNAME			
		done
	else
		if [ $(egrep ^[^:]+:[^\!*] $SHA_FILE | awk -F: '$7 > "'$SSH_VALUE'" {print $1}' | wc -l) -gt 0 ]; then
			warn "Have least user's INACTIVE password lifttime is greater than $SSH_VALUE day. Fixing"
			for USERNAME in $(egrep ^[^:]+:[^\!*] $SHA_FILE | awk -F: '$7 > "'$SSH_VALUE'" {print $1}'); 
			do 
				chage --inactive $SSH_VALUE $USERNAME
			done
		else
			ok "All user's INACTIVE password lifttime is equal or less than $SSH_VALUE day"
		fi
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
