#!/bin/bash

#
# harbian-audit for Debian GNU/Linux 10 or CentOS 8 Hardening
#

#
# 4.6 Activate SELinux (Scored)
# Add by Author : Samson-W (samson@hardenedlinux.org)
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=3

PACKAGES='selinux-basics selinux-policy-default'
SETSTRING="security=selinux" 
APPARMOR_RUN="/sys/kernel/security/apparmor/"

audit_debian () {
	if [ -d APPARMOR_RUN ]; then
		ok "AppArmor was actived. So pass."
		return 0
	fi
	# Only support for Debian 10 (Buster) 
	is_debian_ge_10
	if [ $FNRET = 0 ]; then
    	for PACKAGE in ${PACKAGES}
    	do
        	is_pkg_installed $PACKAGE
        	if [ $FNRET != 0 ]; then
            	crit "$PACKAGE is absent!"
            	FNRET=1
        	fi
    	done
    	if [ $FNRET = 0 ]; then
        	ok "$PACKAGE is installed"
		fi
		if [ $(grep -c "${SETSTRING}" /proc/cmdline) -eq 1 ]; then
			ok "SELinux is actived."
			does_valid_pattern_exist_in_file '/etc/selinux/config' 'SELINUX=enforcing'
			if [ ${FNRET} -eq 0 -a $(getenforce | grep -c 'Enforcing') -eq 1 ]; then
				ok "SELinux is in Enforcing mode."
				FNRET=0
			else	
				crit "SELinux is not in Enforcing mode."
				FNRET=3
			fi
		else	
			crit "SELinux is inactived."
			FNRET=2
		fi
	else
		warn "SELinux check only support Debian 10."
		FNRET=4
	fi
}

audit_centos () {
	if [ $(rpm -qa | grep -c libselinux-utils) -gt 0 ]; then
		if [ $(getenforce | grep -c Enforcing) -eq 1 ]; then
			ok "SELinux is activated and in Enforcing mode."
			FNRET=0
		else
			crit "SELinux is actived and in Enforcing mode."
			FNRET=2
		fi
	else
		crit "SELinux related packages are not installed."
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
	if [ -d $APPARMOR_RUN ]; then
		ok "AppArmor was actived. So pass."
		return 0
	fi
    if [ $FNRET = 0 ]; then
		ok "SELinux is active and in Enforcing mode."
    elif [ $FNRET = 1 ]; then
        warn "$PACKAGE is not installed, install $PACKAGES"
        for PACKAGE in ${PACKAGES}
        do
            apt_install $PACKAGE
        done
    elif [ $FNRET = 2 ]; then
		warn "Set SELinux to activate."
		selinux-activate
    elif [ $FNRET = 3 ]; then
		warn "Set SELinux to enforcing mode, and need reboot"
		replace_in_file '/etc/selinux/config' 'SELINUX=.*' 'SELINUX=enforcing'
	else
		warn "SELinux check only support Debian 10."
    fi
}

# Todo
apply_centos () {
	:
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
		:
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
