#!/bin/bash

#
# harbian-audit for Debian GNU/Linux 7/8/9/10/11/12 or CentOS Hardening
# Modify by: Samson-W (samson@hardenedlinux.org)
#

#
# 5.1.4 Ensure talk server is not enabled (Scored)
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=2

PACKAGES='inetutils-talkd talkd'
FILE='/etc/inetd.conf'
PATTERN='^(talk|ntalk)'
PACKAGES_CENTOS='talk-server'

audit_debian () {
    for PACKAGE in $PACKAGES; do
        is_pkg_installed $PACKAGE
        if [ $FNRET = 0 ]; then
            warn "$PACKAGE is installed, checking configuration"
            does_file_exist $FILE
            if [ $FNRET != 0 ]; then
                ok "$FILE does not exist"
            else
                does_pattern_exist_in_file $FILE $PATTERN
                if [ $FNRET = 0 ]; then
                    crit "$PATTERN exists, $PACKAGE services are enabled!"
                else
                    ok "$PATTERN is not present in $FILE"
                fi
            fi
        else
            ok "$PACKAGE is absent"
        fi
    done
}

audit_centos () {
    for PACKAGE in $PACKAGES_CENTOS; do
        is_pkg_installed $PACKAGE
        if [ $FNRET = 0 ]; then
            crit "$PACKAGE is installed"
        else
            ok "$PACKAGE is absent"
        fi
	done
}

# This function will be called if the script status is on enabled / audit mode
audit () {
	if [ $OS_RELEASE -eq 2 ]; then
		audit_centos
	else
		audit_debian
	fi
}

apply_debian () {
    for PACKAGE in $PACKAGES; do
        is_pkg_installed $PACKAGE
        if [ $FNRET = 0 ]; then
            crit "$PACKAGE is installed, purging it"
			uninstall_pkg $PACKAGE
        else
            ok "$PACKAGE is absent"
        fi
        does_file_exist $FILE
        if [ $FNRET != 0 ]; then
            ok "$FILE does not exist"
        else
            info "$FILE exists, checking patterns"
            does_pattern_exist_in_file $FILE $PATTERN
            if [ $FNRET = 0 ]; then
                warn "$PATTERN is present in $FILE, purging it"
                backup_file $FILE
                ESCAPED_PATTERN=$(sed "s/|\|(\|)/\\\&/g" <<< $PATTERN)
                sed -ie "s/$ESCAPED_PATTERN/#&/g" $FILE
            else
                ok "$PATTERN is not present in $FILE"
            fi
        fi
    done
}

apply_centos () {
    for PACKAGE in $PACKAGES_CENTOS; do
        is_pkg_installed $PACKAGE
        if [ $FNRET = 0 ]; then
            crit "$PACKAGE is installed, purging it"
			uninstall_pkg $PACKAGE
        else
            ok "$PACKAGE is absent"
        fi
    done
}

# This function will be called if the script status is on enabled mode
apply () {
	if [ $OS_RELEASE -eq 2 ]; then
		apply_centos
	else
		apply_debian
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
