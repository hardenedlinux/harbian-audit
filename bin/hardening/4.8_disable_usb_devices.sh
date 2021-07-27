#!/bin/bash

#
# harbian-audit for Debian GNU/Linux 9/10 or CentOS Hardening 
# Modify by: Samson-W (samson@hardenedlinux.org)
#

#
# 4.8 Disable USB storage Devices
# TODO: CentOS 
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=4

BLACKRULEPATTERN='install[[:blank:]].*usb_storage[[:blank:]].*/bin/true'
BLACKRULE='install usb_storage /bin/true'
BLACKCONFILE='/etc/modprobe.d/blacklist.conf'
BLACKCONDIR='/etc/modprobe.d'

audit_debian () {
    SEARCH_RES=0
    for FILE_SEARCHED in $BLACKCONDIR; do
        if [ $SEARCH_RES = 1 ]; then break; fi
        if test -d $FILE_SEARCHED; then
            debug "$FILE_SEARCHED is a directory"
            for file_in_dir in $(ls $FILE_SEARCHED); do
                does_pattern_exist_in_file "$FILE_SEARCHED/$file_in_dir" "^$BLACKRULEPATTERN"
                if [ $FNRET != 0 ]; then
                    debug "$BLACKRULEPATTERN is not present in $FILE_SEARCHED/$file_in_dir"
                else
                    ok "$BLACKRULEPATTERN is present in $FILE_SEARCHED/$file_in_dir"
                    SEARCH_RES=1
                    break
                fi
            done
        else
            does_pattern_exist_in_file "$FILE_SEARCHED" "^$BLACKRULEPATTERN"
            if [ $FNRET != 0 ]; then
                debug "$BLACKRULEPATTERN is not present in $FILE_SEARCHED"
            else
                ok "$BLACKRULEPATTERN is present in $BLACKCONDIR"
                SEARCH_RES=1
            fi
        fi
    done
    if [ $SEARCH_RES = 0 ]; then
        crit "$BLACKRULEPATTERN is not present in $BLACKCONDIR"
    fi
}

audit_centos () {
	:
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

# This function will be called if the script status is on enabled mode
apply () {
    SEARCH_RES=0
    for FILE_SEARCHED in $BLACKCONDIR; do
        if [ $SEARCH_RES = 1 ]; then break; fi
        if test -d $FILE_SEARCHED; then
            debug "$FILE_SEARCHED is a directory"
            for file_in_dir in $(ls $FILE_SEARCHED); do
                does_pattern_exist_in_file "$FILE_SEARCHED/$file_in_dir" "^$BLACKRULEPATTERN"
                if [ $FNRET != 0 ]; then
                    debug "$BLACKRULEPATTERN  is not present in $FILE_SEARCHED/$file_in_dir"
                else
                    ok "$BLACKRULEPATTERN  is present in $FILE_SEARCHED/$file_in_dir"
                    SEARCH_RES=1
                    break
                fi
            done
        else
            does_pattern_exist_in_file "$FILE_SEARCHED" "^$BLACKRULEPATTERN "
            if [ $FNRET != 0 ]; then
                debug "$BLACKRULEPATTERN  is not present in $FILE_SEARCHED"
            else
                ok "$BLACKRULEPATTERN  is present in $BLACKCONDIR"
                SEARCH_RES=1
            fi
        fi
    done
    if [ $SEARCH_RES = 0 ]; then
		warn "$BLACKRULEPATTERN  is not present in $BLACKCONDIR"
		if [ -f $BLACKCONFILE ]; then
			warn "Add $BLACKRULE to $BLACKCONFILE"
			add_end_of_file $BLACKCONFILE "$BLACKRULE"
		else
			warn "Create $BLACKCONFILE and add $BLACKRULE to $BLACKCONFILE"
			touch $BLACKCONFILE
			chmod 644 $BLACKCONFILE
			add_end_of_file $BLACKCONFILE "$BLACKRULE"
		fi
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
