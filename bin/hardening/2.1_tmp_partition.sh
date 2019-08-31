#!/bin/bash

#
# harbian audit Debian 7/8/9 or CentOS Hardening
# Modify by: Samson-W (sccxboy@gmail.com)
#

#
# 2.1 Create Separate Partition/filesystem for /tmp (Scored)
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=2

# Quick factoring as many script use the same logic
PARTITION="/tmp"
TMPMOUNTNAME="tmp.mount"

# This function will be called if the script status is on enabled / audit mode
audit () {
    info "Verifying that $PARTITION is a filesystem/partition"
    FNRET=0
    #If /tmp is set in /etc/fstab, only check /etc/fstab and disable tmp.mount service if it's exist
    is_a_partition "$PARTITION"
    if [ $FNRET -eq 0 ]; then
		ok "$PARTITION is a partition"
		is_mounted "$PARTITION"
		if [ $FNRET -gt 0 ]; then
			warn "$PARTITION is not mounted"
			FNRET=2
		else
			ok "$PARTITION is mounted"
			FNRET=0
		fi
	else
    	warn "$PARTITION is not partition in /etc/fstab, check tmp.mount service"
		if [ $(systemctl | grep -c "tmp.mount[[:space:]]*loaded[[:space:]]active[[:space:]]mounted") -eq 1 ]; then
	 		ok "$TMPMOUNTNAME service is active!"
       		is_mounted "$PARTITION"
			if [ $FNRET -gt 0 ]; then
       			warn "$PARTITION is not mounted"
           		FNRET=3
        	else
       			ok "$PARTITION is mounted"
          		FNRET=0
			fi
		else
    		crit "$TMPMOUNTNAME service is not active!"
			FNRET=4			
		fi
	fi
}

# This function will be called if the script status is on enabled mode
apply () {
	if [ $FNRET = 0 ]; then
		ok "$PARTITION is correctly set"
	elif [ $FNRET = 1 ]; then
        crit "$PARTITION is not a partition, correct this by yourself, I cannot help you here"
	elif [ $FNRET = 2 ]; then
		warn "mounting $PARTITION"
        mount $PARTITION
	elif [ $FNRET = 3 ]; then
        $SUDO_CMD systemctl daemon-reload
        $SUDO_CMD systemctl start "$TMPMOUNTNAME"
	elif [ $FNRET = 4 ]; then
        $SUDO_CMD systemctl enable "$TMPMOUNTNAME"
	    $SUDO_CMD systemctl daemon-reload 
	    $SUDO_CMD systemctl start "$TMPMOUNTNAME"
	fi
}

# This function will check config parameters required
check_config() {
    # No parameter for this script
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
