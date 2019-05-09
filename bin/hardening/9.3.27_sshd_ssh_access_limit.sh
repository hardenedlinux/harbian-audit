#!/bin/bash

#
# harbian audit 9 Hardening
#

#
# 9.3.27 Ensure SSH access is limited (Scored)
# Auther: Samson-W (sccxboy@gmail.com)
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=3

PACKAGE='openssh-server'
FILE='/etc/ssh/sshd_config'
ALLOWUSER='AllowUsers[[:space:]]*\*'
ALLOWGROUP='AllowGroups[[:space:]]*\*'
DENYUSER='DenyUsers[[:space:]]*nobody'
DENYGROUP='DenyGroups[[:space:]]*nobody'

ALLOWUSER_RET=1
ALLOWGROUP_RET=1
DENYUSER_RET=1
DENYGROUP_RET=1

# This function will be called if the script status is on enabled / audit mode
audit () {
    is_pkg_installed $PACKAGE
    if [ $FNRET != 0 ]; then
        crit "$PACKAGE is not installed!"
    else
        ok "$PACKAGE is installed"
		if [ $(sshd -T  | grep -ic $ALLOWUSER) -eq 1 ]; then 
			crit "AllowUsers is not set!"
		else
			ok "AllowUsers has set limit."
			ALLOWUSER_RET=0
		fi

		if [ $(sshd -T  | grep -ic $ALLOWGROUP) -eq 1 ]; then 
			crit "AllowGroups is not set!"
		else
			ok "AllowGroups has set limit."
			ALLOWGROUP_RET=0
		fi
		if [ $(sshd -T  | grep -ic $DENYUSER) -eq 1 ]; then 
			crit "DenyUsers is not set!"
		else
			ok "DenyUsers has set limit."
			DENYUSER_RET=0
		fi
		if [ $(sshd -T  | grep -ic $DENYGROUP) -eq 1 ]; then 
			crit "DenyGroups is not set!"
		else
			ok "DenyGroups has set limit."
			DENYGROUP_RET=0
		fi
	fi
}

# This function will be called if the script status is on enabled mode
apply () {
    is_pkg_installed $PACKAGE
    if [ $FNRET = 0 ]; then
        ok "$PACKAGE is installed"
    else
        crit "$PACKAGE is absent, installing it"
        apt_install $PACKAGE
    fi
	if [ $ALLOWUSER_RET -eq 1 ]; then
		warn "AllowUsers is not set! Need manual operation set it."
	else
		ok "AllowUsers has set limit."
	fi
	if [ $ALLOWGROUP_RET -eq 1 ]; then
		warn "AllowGroups is not set! Need manual operation set it."
	else
		ok "AllowGroups has set limit."
	fi
	if [ $DENYUSER_RET -eq 1 ]; then
		warn "DenyUsers is not set! Need manual operation set it."
	else
		ok "DenyUsers has set limit."
	fi
	if [ $DENYGROUP_RET -eq 1 ]; then
		warn "DenyGroups is not set! Need manual operation set it."
	else
		ok "DenyGroups has set limit."
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
