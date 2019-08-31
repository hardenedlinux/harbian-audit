#!/bin/bash

#
# harbian audit Debian 9/CentOS Hardening
# Modify by: Samson-W (samson@hardenedlinux.org)
#

#
# 1.1 Install Updates, Patches and Additional Security Software (Scored)
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=3


audit_debian ()
{
    info "Checking if apt needs an update"
    apt_update_if_needed 
    info "Fetching upgrades ..."
    apt_check_updates "CIS_APT"
    if [ $FNRET -gt 0 ]; then
        crit "$RESULT"
        FNRET=1
    else
        ok "No upgrades available"
        FNRET=0
    fi
}

audit_redhat ()
{
	info "Checking if yum needs an update"
	info "Fetching upgrades ..."
	yum_check_updates
	if [ $FNRET -eq 100 ]; then
		crit "There are packages available for an update!"
	elif [ $FNRET -eq 0 ]; then
		ok "No upgrades available"
	else
		crit "Call yum_check_updates function error!"
	fi
}

# This function will be called if the script status is on enabled / audit mode
audit () 
{
	if [ $OS_RELEASE -eq 1 ]; then
		audit_debian
	elif [ $OS_RELEASE -eq 2 ]; then
		audit_redhat
	else
		crit "Current OS is not support!"
		FNRET=44 
	fi
}

apply_debian ()
{
    if [ $FNRET -eq 1 ]; then 
        info "Applying Upgrades..."
        DEBIAN_FRONTEND='noninteractive' apt-get -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' upgrade -y
	else
		ok "No Upgrades to apply"
    fi
}

apply_redhat ()
{
	if [ $FNRET -eq 100 ]; then 
		info "Applying Upgrades..."
		yum upgrade -y
	elif [ $FNRET -eq 0 ]; then 
		ok "No Upgrades to apply"
	else
		crit "Call yum_check_updates function error!"
    fi
}

# This function will be called if the script status is on enabled mode
apply () 
{
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
    # No parameters for this function
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
