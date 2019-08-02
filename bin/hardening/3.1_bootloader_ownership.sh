#!/bin/bash

#
# harbian audit 7/8/9/10 or CentOS  Hardening
# Modify by: Samson-W (samson@hardenedlinux.org)
#

#
# 3.1 Set User/Group Owner on bootloader config (Scored)
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=1

# Assertion : Grub Based.

FILE='/boot/grub/grub.cfg'
FILE_GRUB2='/boot/grub2/grub.cfg'
USER='root'
GROUP='root'

# This function will be called if the script status is on enabled / audit mode
audit () {
	if [ $OS_RELEASE -eq 2 ]; then
		has_file_correct_ownership $FILE_GRUB2 $USER $GROUP
		if [ $FNRET = 0 ]; then
			ok "$FILE_GRUB2 has correct ownership"
		else
			crit "$FILE_GRUB2 ownership was not set to $USER:$GROUP"	
		fi 
	else
		has_file_correct_ownership $FILE $USER $GROUP
		if [ $FNRET = 0 ]; then
			ok "$FILE has correct ownership"
		else
			crit "$FILE ownership was not set to $USER:$GROUP"
		fi 
	fi
}

# This function will be called if the script status is on enabled mode
apply () {
	if [ $OS_RELEASE -eq 2 ]; then	
		has_file_correct_ownership $FILE_GRUB2 $USER $GROUP
		if [ $FNRET = 0 ]; then
			ok "$FILE_GRUB2 has correct ownership"
		else
			info "fixing $FILE_GRUB2 ownership to $USER:$GROUP"
			chown $USER:$GROUP $FILE_GRUB2
		fi
	else
		has_file_correct_ownership $FILE $USER $GROUP
		if [ $FNRET = 0 ]; then
			ok "$FILE has correct ownership"
		else
			info "fixing $FILE ownership to $USER:$GROUP"
			chown $USER:$GROUP $FILE
		fi
	fi
}

# This function will check config parameters required
check_config() {
	if [ $OS_RELEASE -eq 2 ]; then
		is_pkg_installed "grub2-pc"
	else
		is_pkg_installed "grub-pc"
	fi
	if [ $FNRET != 0 ]; then
		warn "Grub is not installed, not handling configuration"
		exit 128
	fi

	does_user_exist $USER
	if [ $FNRET != 0 ]; then
		crit "$USER does not exist"
		exit 128
	fi

	does_group_exist $GROUP
	if [ $FNRET != 0 ]; then
		crit "$GROUP does not exist"
		exit 128
	fi

	if [ $OS_RELEASE -eq 2 ]; then
		does_file_exist $FILE_GRUB2
    	if [ $FNRET != 0 ]; then
        	crit "$FILE_GRUB2 does not exist"
        	exit 128
    	fi
	else
    	does_file_exist $FILE
    	if [ $FNRET != 0 ]; then
        	crit "$FILE does not exist"
        	exit 128
    	fi
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
