#!/bin/bash

#
# harbian audit 7/8/9/10 or CentOS Hardening
# Modify by: Samson-W (samson@hardenedlinux.org)
# todo: SELinux

#
# 4.5 Activate AppArmor/SELinux (Scored)
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

audit_debian () {
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
        if [ $( grep -w "^${KEYWORD}" ${GRUBFILE} | grep -c ${PATTERN}) -eq 1 ]; then
            ok "There are ${SETSTRING} to ${KEYWORD} in ${GRUBFILE}"
            is_mounted  "/sys/kernel/security"
            if [ ${FNRET} -eq 0 -a $(/usr/sbin/apparmor_status 2>&1 | grep -c "apparmor filesystem is not mounted.") -eq 1 ]; then
                crit "AppArmor profiles not enable in the system "
                FNRET=3
            elif [ ${FNRET} -eq 0 -a $(/usr/sbin/apparmor_status | grep 'profiles are loaded' | awk '{print $1}') -gt 0 ]; then 
                ok "AppArmor profiles is enable in the system "
                FNRET=0
            fi
        else
            crit "There are not set ${SETSTRING} to ${KEYWORD} in ${GRUBFILE}"
            FNRET=2
        fi
    fi
}

# Todo
audit_redhat () {
	:	
}

# This function will be called if the script status is on enabled / audit mode
audit () {
	if [ $OS_RELEASE -eq 1 ]; then
        audit_debian
    elif [ $OS_RELEASE -eq 2 ]; then
        audit_redhat
    else
        crit "Current OS is not support!"
        FNRET=44
    fi
}

apply_debian () {
    if [ $FNRET = 0 ]; then
        ok "AppArmor profiles is enable in the system "
    elif [ $FNRET = 1 ]; then
        warn "$PACKAGE is not installed, install $PACKAGES"
        for PACKAGE in ${PACKAGES}
        do
            apt_install $PACKAGE
        done
    elif [ $FNRET = 2 ]; then
        warn "Set ${SETSTRING} to ${GRUBFILE} in ${GRUBFILE}, need to reboot the system and enable AppArmor profiles after setting it."
        sed -i "s;\(${KEYWORD}=\)\(\".*\)\(\"\);\1\2 ${SETSTRING}\3;" ${GRUBFILE}
        /usr/sbin/update-grub2
    elif [ $FNRET = 3 ]; then
        warn "Enable AppArmor profiles in the system "
        /usr/sbin/aa-enforce /etc/apparmor.d/*
    fi
}

# Todo
apply_redhat () {
	:
}

# This function will be called if the script status is on enabled mode
apply () {
	if [ $OS_RELEASE -eq 1 ]; then
        apply_debian
    elif [ $OS_RELEASE -eq 2 ]; then
        apply_redhat
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
