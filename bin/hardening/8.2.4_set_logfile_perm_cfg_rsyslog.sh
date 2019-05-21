#!/bin/bash

#
# harbian audit 7/8/9  Hardening
#

#
# 8.2.4 Create and Set Permissions on rsyslog Log Files by conf file (Scored)
# Author : Samson wen, Samson <sccxboy@gmail.com>
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=3

PACKAGE_NG='syslog-ng'

PERMISSIONS='640'
USER='root'
GROUP='adm'

OWNER_USER_KEY='$FileOwner'
OWNER_GROUP_KEY='$FileGroup'
PERMIS_KEY='$FileCreateMode'

FILE='/etc/rsyslog.conf'
FILE_WIDE='/etc/rsyslog.d/*.conf'

# This function will be called if the script status is on enabled / audit mode
audit () {
	is_pkg_installed $PACKAGE_NG	
	if [ $FNRET = 0 ]; then
		ok "$PACKAGE_NG has installed, so pass."
	else
		does_file_exist "$FILE"
    	if [ $FNRET != 0 ]; then
			crit "$FILE is not exist! "
		else
			does_pattern_exist_in_file "$FILE" "^\\$OWNER_USER_KEY"
    		if [ $FNRET != 0 ]; then
				crit "$OWNER_USER_KEY is not exist in $FILE"
			else
				OWNER_USER_NAME=$(grep "^\\$OWNER_USER_KEY" $FILE $FILE_WIDE 2>>/dev/null | awk -F: '{print $2}' | awk '{print $2}')	
				if [ "$OWNER_USER_NAME" != "$USER" ]; then
					crit "File owner not set is root!"
				else
					ok "File owner set is root!"
				fi
			fi
			does_pattern_exist_in_file "$FILE" "^\\$OWNER_GROUP_KEY"
    		if [ $FNRET != 0 ]; then
				crit "$OWNER_GROUP_KEY is not exist in $FILE"
			else
				OWNER_GROUP_NAME=$(grep "^\\$OWNER_GROUP_KEY" $FILE $FILE_WIDE 2>>/dev/null | awk -F: '{print $2}' | awk '{print $2}')	
				if [ "$OWNER_GROUP_NAME" != "$GROUP" ]; then
					crit "File group not set is $GROUP!"
				else
					ok "File group set is $GROUP!"
				fi
			fi

			does_pattern_exist_in_file "$FILE" "^\\$PERMIS_KEY"
    		if [ $FNRET != 0 ]; then
				crit "$PERMIS_KEY is not exist in $FILE"
			else
				PERMIS_KEY_NAME=$(grep "^\\$PERMIS_KEY" $FILE $FILE_WIDE 2>>/dev/null | awk -F: '{print $2}' | awk '{print $2}')	
				if [ "$PERMIS_KEY_NAME" != "$PERMISSIONS" -a "$PERMIS_KEY_NAME" != "0$PERMISSIONS" ]; then
					crit "File permissions not set is $PERMISSIONS!"
				else
					ok "File permissions set is $PERMISSIONS!"
				fi
			fi
		fi
	fi
}

# This function will be called if the script status is on enabled mode
apply () {
	is_pkg_installed $PACKAGE_NG	
	if [ $FNRET = 0 ]; then
		ok "$PACKAGE_NG has installed, so pass."
	else
		does_file_exist "$FILE"
    	if [ $FNRET != 0 ]; then
			crit "$FILE is not exist! Please check."
		else
			does_pattern_exist_in_file "$FILE" "^\\$OWNER_USER_KEY"
    		if [ $FNRET != 0 ]; then
				warn "$OWNER_USER_KEY is not exist in $FILE, add it"
				add_end_of_file $FILE "$OWNER_USER_KEY $USER"
			else
				OWNER_USER_NAME=$(grep "^\\$OWNER_USER_KEY" $FILE $FILE_WIDE 2>>/dev/null | awk -F: '{print $2}' | awk '{print $2}')	
				if [ "$OWNER_USER_NAME" != "$USER" ]; then
					warn "File owner not set is $USER! Reset it"
					replace_in_file $FILE "$OWNER_USER_KEY.*" "$OWNER_USER_KEY $USER"
				else
					ok "File owner set is $USER!"
				fi
			fi
			does_pattern_exist_in_file "$FILE" "^\\$OWNER_GROUP_KEY"
    		if [ $FNRET != 0 ]; then
				warn "$OWNER_GROUP_KEY is not exist in $FILE, add it"
				add_end_of_file $FILE "$OWNER_GROUP_KEY $GROUP"
			else
				OWNER_GROUP_NAME=$(grep "^\\$OWNER_GROUP_KEY" $FILE $FILE_WIDE 2>>/dev/null | awk -F: '{print $2}' | awk '{print $2}')	
				if [ "$OWNER_GROUP_NAME" != "$GROUP" ]; then
					warn "File group not set is $GROUP! Reset it"
					replace_in_file $FILE  "$OWNER_GROUP_KEY.*" "$OWNER_GROUP_KEY $GROUP"
				else
					ok "File group set is $GROUP!"
				fi
			fi

			does_pattern_exist_in_file "$FILE" "^\\$PERMIS_KEY"
    		if [ $FNRET != 0 ]; then
				warn "$PERMIS_KEY is not exist in $FILE, add it"
				add_end_of_file $FILE "$PERMIS_KEY $PERMISSIONS"
			else
				PERMIS_KEY_NAME=$(grep "^\\$PERMIS_KEY" $FILE $FILE_WIDE 2>>/dev/null | awk -F: '{print $2}' | awk '{print $2}')	
				if [ "$PERMIS_KEY_NAME" != "$PERMISSIONS" -a "$PERMIS_KEY_NAME" != "0$PERMISSIONS" ]; then
					warn "File permissions not set is $PERMISSIONS! Reset it"
					replace_in_file $FILE "$PERMIS_KEY.*" "$PERMIS_KEY $PERMISSIONS"
				else
					ok "File permissions set is $PERMISSIONS!"
				fi
			fi
		fi
	fi
}

# This function will create the config file for this check with default values
create_config() {
    cat <<EOF
status=disabled
EOF
}

# This function will check config parameters required
check_config() {
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
