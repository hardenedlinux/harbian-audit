#!/bin/bash

#
# harbian-audit for Debian GNU/Linux 7/8/9  Hardening
#

#
# 10.1.5 Ensure inactive password lock is 30 days or less (Scored)
# Author: Samson-W (sccxboy@gmail.com)
# STIG for Ubuntu_16-04_LTS_STIG_V1R2_Manual: INACTIVE=35
# STIG for U_Red_Hat_Enterprise_Linux_7_V2R5: INACTIVE=0
# 
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=3

OPTIONS='INACTIVE=30'
OPTIONS_CENTOS='INACTIVE=0'
SHA_FILE='/etc/shadow'
DISABLE_V='-1'
FILE='/etc/default/useradd'

audit_debian () {
		SSH_PARAM=$(echo $OPTIONS | cut -d= -f 1)
		SSH_VALUE=$(echo $OPTIONS | cut -d= -f 2)
		INACTIVE_V=$(useradd -D | grep $SSH_PARAM | awk -F= '{print $2}')
		if [ $INACTIVE_V -eq $DISABLE_V ]; then
			crit "INACTIVE feature has disabled."
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

audit_centos () {
	SSH_PARAM=$(echo $OPTIONS | cut -d= -f 1)
	SSH_VALUE=$(echo $OPTIONS | cut -d= -f 2)
	INACTIVE_V=$(useradd -D | grep $SSH_PARAM | awk -F= '{print $2}')
	if [ $INACTIVE_V -eq $DISABLE_V ]; then
		crit "INACTIVE feature has disabled."
	elif [ $INACTIVE_V -eq $SSH_VALUE ]; then
		ok "All user's INACTIVE value has set $SSH_VALUE: disables the account as soon as the password has expired"
	else
		crit "All user's INACTIVE value is not set $SSH_VALUE: disables the account as soon as the password has expired"
	fi
}

# This function will be called if the script status is on enabled / audit mode
audit () {
    if [ $OS_RELEASE -eq 1 ]; then
		audit_debian
	elif [ $OS_RELEASE -eq 2 ]; then
		audit_centos
	else
		warn "Current OS is not support!"	
	fi
}

apply_debian () {
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

apply_centos () {
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
			warn "All user's INACTIVE value is not set $SSH_VALUE, fixing it."
			for USERNAME in $(egrep ^[^:]+:[^\!*] $SHA_FILE | awk -F: '$7 > "'$SSH_VALUE'" {print $1}'); 
			do 
				chage --inactive $SSH_VALUE $USERNAME
			done
		else
			ok "All user's INACTIVE value has set $SSH_VALUE: disables the account as soon as the password has expired"
		fi
	fi
}

# This function will be called if the script status is on enabled mode
apply () {
    if [ $OS_RELEASE -eq 1 ]; then
		apply_debian
	elif [ $OS_RELEASE -eq 2 ]; then
		apply_centos
	else
		warn "Current OS is not support!"	
	fi
}

# This function will check config parameters required
check_config() {
    if [ $OS_RELEASE -eq 1 ]; then
		:
	elif [ $OS_RELEASE -eq 2 ]; then
		OPTIONS=$OPTIONS_CENTOS
	else
		warn "Current OS is not support!"	
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
