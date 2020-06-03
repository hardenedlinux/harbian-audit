#!/bin/bash

#
# harbian-audit for Debian GNU/Linux 7/8/9/10 or CentOS Hardening
# Modify by: Samson-W (samson@hardenedlinux.org)

#
# 4.5 Activate AppArmor (Scored)
# Add by Author : Samson wen, Samson <sccxboy@gmail.com>
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=3

PACKAGES='apparmor apparmor-profiles apparmor-utils'
KEYWORD="GRUB_CMDLINE_LINUX"
PATTERN="apparmor=1[[:space:]]*security=apparmor" 
SETSTRING="apparmor=1 security=apparmor" 
GRUBFILE='/etc/default/grub'
SERVICENAME='apparmor.service'
SELINUXSETSTRING="security=selinux" 

audit_debian () {
	if [ $(grep -c "${SELINUXSETSTRING}" /proc/cmdline) -eq 1 ]; then
		ok "SELinux was actived. So pass."
		return 0
	fi
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
		# Since Debian 10 (Buster), AppArmor is enabled by default. It's a system service 
		is_debian_ge_10
		if [ $FNRET = 0 ]; then
			is_service_active $SERVICENAME
			if [ $FNRET -eq 0 ]; then
                ok "$SERVICENAME is active!"
                FNRET=0
			else
            	crit "$SERVICENAME is inactive!"
            	FNRET=2
			fi
		else
			if [ $(grep -c "${SETSTRING}" /proc/cmdline) -eq 1 ]; then
				ok "There are ${SETSTRING} to ${KEYWORD} in ${GRUBFILE}"
            	is_mounted  "/sys/kernel/security"
            	if [ ${FNRET} -eq 0 -a $(/usr/sbin/aa-status 2>&1 | grep -c "apparmor filesystem is not mounted.") -eq 1 ]; then
                	crit "AppArmor profiles not enable in the system "
                	FNRET=3
            	elif [ ${FNRET} -eq 0 -a $(/usr/sbin/aa-status | grep 'profiles are loaded' | awk '{print $1}') -gt 0 ]; then 
                	ok "AppArmor profiles is enable in the system "
                	FNRET=0
            	fi
        	else
				crit "There are ${SETSTRING} to ${KEYWORD} not in ${GRUBFILE}"
            	FNRET=2
        	fi
		fi
    fi
}

audit_centos () {
	ok "AppArmor is only support for Debian, So pass!"
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
	if [ $(grep -c "${SELINUXSETSTRING}" /proc/cmdline) -eq 1 ]; then
		ok "SELinux was actived. So pass."
		return 0
	fi
    if [ $FNRET = 0 ]; then
        ok "AppArmor profiles is enable in the system "
    elif [ $FNRET = 1 ]; then
        warn "$PACKAGE is not installed, install $PACKAGES"
        for PACKAGE in ${PACKAGES}
        do
            apt_install $PACKAGE
        done
    elif [ $FNRET = 2 ]; then
		# Since Debian 10 (Buster), AppArmor is enabled by default. It's a system service 
		is_debian_ge_10
		if [ $FNRET = 0 ]; then
			warn "Start $SERVICENAME"
			systemctl start $SERVICENAME
		else
        	warn "Set ${SETSTRING} to ${GRUBFILE} in ${GRUBFILE}, need to reboot the system and enable AppArmor profiles after setting it."
        	sed -i "s;\(${KEYWORD}=\)\(\".*\)\(\"\);\1\2 ${SETSTRING}\3;" ${GRUBFILE}
        	/usr/sbin/update-grub2
		fi
    elif [ $FNRET = 3 ]; then
        warn "Enable AppArmor profiles in the system "
        /usr/sbin/aa-enforce /etc/apparmor.d/*
    fi
}

apply_centos () {
	ok "AppArmor is only support for Debian, So pass!"
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
