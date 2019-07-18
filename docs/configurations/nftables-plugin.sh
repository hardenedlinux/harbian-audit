#!/bin/sh

# This file is part of netfilter-persistent
# Copyright (C) 2019, Samson W <samson@hardenedlinux.org>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation, either version 3
# of the License, or (at your option) any later version.

set -e

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
NFT_RULESET="/etc/nftables.conf"
NFT_CMD=$(which nft)

load_rules()
{
	#load nft rules
	if [ ! -f ${NFT_RULESET} ]; then
		echo "Warning: nft ruleset file ${NFT_RULESET} is not exist!"
	else
		${NFT_CMD} -f ${NFT_RULESET}
	fi
}

save_rules()
{
	if [ ! -f ${NFT_RULESET} ]; then
		echo "Warning: nft ruleset file ${NFT_RULESET} is not exist!"
		touch ${NFT_RULESET}
		chmod 0640 ${NFT_RULESET}
        else	
		:
	fi
	${NFT_CMD} list ruleset -n > ${NFT_RULESET}
}

flush_rules()
{
	if [ ! -f ${NFT_CMD} ]; then
		echo "Warning: nft ruleset file ${NFT_CMD} is not exist!"
	else
		${NFT_CMD} flush ruleset 
	fi
}

case "$1" in
start|restart|reload|force-reload)
	load_rules
	;;
save)
	save_rules
	;;
stop)
	# Why? because if stop is used, the firewall gets flushed for a variable
	# amount of time during package upgrades, leaving the machine vulnerable
	# It's also not always desirable to flush during purge
	echo "Automatic flushing disabled, use \"flush\" instead of \"stop\""
	;;
flush)
	flush_rules
	;;
*)
    echo "Usage: $0 {start|restart|reload|force-reload|save|flush}" >&2
    exit 1
    ;;
esac
