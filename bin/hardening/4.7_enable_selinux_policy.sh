#!/bin/bash

#
# harbian-audit for Debian GNU/Linux 9/10 or CentOS 8 Hardening
#

#
# 4.7 Enable SELinux targeted policy (Scored)
# Add by Author : Samson-W (samson@hardenedlinux.org)
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=3

SELINUXCONF_FILE='/etc/selinux/config'
SELINUXTYPE_VALUE='SELINUXTYPE=default'

audit_debian () {
	set +e
	check_aa_status
	set -e
	if [ $FNRET = 0 ]; then
		ok "AppArmor was actived. So pass."
		return 0
	fi
	does_valid_pattern_exist_in_file $SELINUXCONF_FILE $SELINUXTYPE_VALUE
	if [ ${FNRET} -eq 0 ]; then
		ok "SELinux targeted policy was enabled."			
		FNRET=0
	else	
		crit "SELinux targeted policy is not enable."			
		FNRET=1
	fi
}

audit_centos () {
	does_valid_pattern_exist_in_file $SELINUXCONF_FILE $SELINUXTYPE_VALUE
	if [ ${FNRET} -eq 0 ]; then
		ok "SELinux targeted policy was enabled."			
		FNRET=0
	else	
		crit "SELinux targeted policy is not enable."			
		FNRET=1
	fi
}

# This function will be called if the script status is on enabled / audit mode
audit () {
	if [ $OS_RELEASE -eq 1 ]; then
        audit_debian
    elif [ $OS_RELEASE -eq 2 ]; then
        audit_centos
    else
        crit "Current OS is not support!"
        FNRET=44
    fi
}

apply_debian () {
	set +e
	check_aa_status
	set -e
	if [ $FNRET = 0 ]; then
		ok "AppArmor was actived. So pass."
		return 0
	fi
    if [ $FNRET = 0 ]; then
		ok "SELinux targeted policy was enabled."			
    elif [ $FNRET = 1 ]; then
		warn "Set SELinux targeted policy to enable, and need reboot"			
		replace_in_file $SELINUXCONF_FILE 'SELINUXTYPE=.*' $SELINUXTYPE_VALUE
	else
		:
    fi
}

apply_centos () {
    if [ $FNRET = 0 ]; then
		ok "SELinux targeted policy was enabled."			
    elif [ $FNRET = 1 ]; then
		warn "Set SELinux targeted policy to enable, and need reboot"			
		replace_in_file $SELINUXCONF_FILE 'SELINUXTYPE=.*' $SELINUXTYPE_VALUE
	else
		:
	fi
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
		SELINUXTYPE_VALUE='SELINUXTYPE=targeted'
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
