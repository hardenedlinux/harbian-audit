#!/bin/bash

#
# harbian-audit for Debian GNU/Linux 7/8/9/10 or CentOS Hardening
# Modify by: Samson-W (samson@hardenedlinux.org)

#
# 2.17 Set Sticky Bit on All World-Writable Directories (Scored)
#

#set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=2

# This function will be called if the script status is on enabled / audit mode
audit () {
    info "Checking if setuid is set on world writable Directories"
    RESULT=$(df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' $SUDO_CMD find '{}' -xdev -type d \( -perm -0002 -a ! -perm -1000 \) -print 2>/dev/null)
    if [ ! -z "$RESULT" ]; then
        crit "Some world writable directories are not on sticky bit mode!"
        FORMATTED_RESULT=$(sed "s/ /\n/g" <<< $RESULT | sort | uniq | tr '\n' ' ')
        crit "$FORMATTED_RESULT"
    else
        ok "All world writable directories have a sticky bit"
    fi
	# Check sticky dir group-owned is root
    RESULT=$(df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' $SUDO_CMD find '{}' -xdev -type d ! -group root \( -perm -0002 -a -perm -1000 \) -print 2>/dev/null)
    if [ ! -z "$RESULT" ]; then
        crit "Some world writable directories are sticky bit mode, but not group owned is root!"
        FORMATTED_RESULT=$(sed "s/ /\n/g" <<< $RESULT | sort | uniq | tr '\n' ' ')
        crit "$FORMATTED_RESULT"
    else
        ok "All world writable directories have a sticky bit, and group owner is root."
    fi
}

# This function will be called if the script status is on enabled mode
apply () {
    RESULT=$(df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -type d \( -perm -0002 -a ! -perm -1000 \) -print 2>/dev/null)
    if [ ! -z "$RESULT" ]; then
        df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -type d -perm -0002 2>/dev/null | xargs chmod a+t
    else
        ok "All world writable directories have a sticky bit, nothing to apply"
    fi
    RESULT=$(df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' $SUDO_CMD find '{}' -xdev -type d ! -group root \( -perm -0002 -a -perm -1000 \) -print 2>/dev/null)
    if [ ! -z "$RESULT" ]; then
		df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' $SUDO_CMD find '{}' -xdev -type d ! -group root \( -perm -0002 -a -perm -1000 \) -print 2>/dev/null | xargs chgrp root 
    else
        ok "All world writable directories have a sticky bit, and group owner is root."
    fi
}

# This function will check config parameters required
check_config() {
    # No param for this function
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
