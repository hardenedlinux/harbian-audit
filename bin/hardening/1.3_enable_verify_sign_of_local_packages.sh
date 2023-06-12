#!/bin/bash

#
# harbian-audit for Debian GNU/Linux Debian 9/10/11/12 or CentOS 8 Hardening
#

#
# 1.3 Enable verify the signature of local packages (Scored)
# Dependance pkg: debsig-verify
# Author : Samson wen, Samson <sccxboy@gmail.com>
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=2
OPTION='no-debsig'
CONFFILE='/etc/dpkg/dpkg.cfg'

YUM_OPTION='localpkg_gpgcheck'
YUM_CONFFILE='/etc/yum.conf'

audit_debian () {
    if [ $(grep -v "^#" ${CONFFILE} | grep -c ${OPTION}) -gt 0 ]; then
        crit "The signature of local packages option is disable "
        FNRET=1
    else
        ok "The signature of local packages option is enable "
        FNRET=0
    fi
}

audit_centos ()
{
    if [ $(grep -c "^$YUM_OPTION" $YUM_CONFFILE) -gt 0 ]; then
        if [ $(grep "^$YUM_OPTION" $YUM_CONFFILE | awk -F"=" '{print $2}') -eq 1 ]; then
            ok "The signature of packages option is enable "
            FNRET=0
        else
            crit "The signature of packages option is disable "
            FNRET=1
        fi
    else
        crit "Option $YUM_OPTION is not set in $YUM_CONFFILE!"
        FNRET=2
    fi
}

# This function will be called if the script status is on enabled / audit mode
audit()
{
    if [ $OS_RELEASE -eq 2 ]; then
        audit_centos
    else
        audit_debian
    fi
}

apply_debian () {
    if [ $FNRET = 0 ]; then 
        ok "The signature of local packages option is enable "
    else
        warn "Set to enabled signature of local packages option"
			backup_file $CONFFILE
            sed -i "s/^${OPTION}/#&/" ${CONFFILE}
    fi
}

apply_centos () {
    if [ $FNRET = 0 ]; then
        ok "The signature of packages option is enable "
    elif [ $FNRET = 1 ]; then
		backup_file $YUM_CONFFILE
        warn "Set to enabled signature of packages option"
        sed -i "s/$YUM_OPTION=.*/$YUM_OPTION=1/g" $YUM_CONFFILE
    else
		backup_file $YUM_CONFFILE
        warn "Add $YUM_OPTION option to $YUM_CONFFILE"
        add_end_of_file $YUM_CONFFILE "$YUM_OPTION=1"
    fi
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
