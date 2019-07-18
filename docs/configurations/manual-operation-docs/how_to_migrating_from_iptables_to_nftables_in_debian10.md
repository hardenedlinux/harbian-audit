# How to migrating from iptables to nftables in debian Buster
Debian Buster uses the nftables framework by default. 

## Pre-install  
```
$ sudo apt install nftables
```

## Check iptables link point 
Starting with Debian Buster, nf_tables is the default backend when using iptables, by means of the iptables-nft layer (i.e, using iptables syntax with the nf_tables kernel subsystem). This also affects ip6tables, arptables and ebtables.

You can switch back and forth between iptables-nft and iptables-legacy by means of update-alternatives (same applies to arptables and ebtables).  

Check iptables currently link:
```
$ sudo update-alternatives  --display iptables
iptables - auto mode
  link best version is /usr/sbin/iptables-nft
  link currently points to /usr/sbin/iptables-nft
  link iptables is /usr/sbin/iptables
  slave iptables-restore is /usr/sbin/iptables-restore
  slave iptables-save is /usr/sbin/iptables-save
/usr/sbin/iptables-legacy - priority 10
  slave iptables-restore: /usr/sbin/iptables-legacy-restore
  slave iptables-save: /usr/sbin/iptables-legacy-save
/usr/sbin/iptables-nft - priority 20
  slave iptables-restore: /usr/sbin/iptables-nft-restore
  slave iptables-save: /usr/sbin/iptables-nft-save
```
If you see above, don't need switching, if currently link to iptables-legacy, need use command to switching to iptables-nft:
```
$ sudo update-alternatives --set iptables /usr/sbin/iptables-nft
$ sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-nft
$ sudo update-alternatives --set arptables /usr/sbin/arptables-nft
$ sudo update-alternatives --set ebtables /usr/sbin/ebtables-nft
$ sudo update-alternatives  --display iptables
```
## Migrating  
move from an existing iptables ruleset to nftables:

### Command translation  
You can generate a translation of an iptables/ip6tables command to know the nftables equivalent. 
```
$ sudo iptables-translate -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -j ACCEPT
nft add rule ip filter INPUT tcp dport 22 ct state new counter accept
$ sudo ip6tables-translate -A FORWARD -i eth0 -o eth3 -p udp -m multiport --dports 111,222 -j ACCEPT
nft add rule ip6 filter FORWARD iifname "eth0" oifname "eth3" meta l4proto udp udp dport { 111,222} counter accept
```

Instead of translating command by command, you can translate your whole ruleset in a single run: 

```
$ sudo iptables-save > save.txt
$ sudo iptables-restore-translate -f save.txt
# Translated by iptables-restore-translate v1.8.2 on Fri Jul 12 04:33:36 2019
add table ip filter
add chain ip filter INPUT { type filter hook input priority 0; policy drop; }
add chain ip filter FORWARD { type filter hook forward priority 0; policy drop; }
add chain ip filter OUTPUT { type filter hook output priority 0; policy drop; }
add chain ip filter LOGDROP
add rule ip filter INPUT iifname "lo" counter accept
add rule ip filter INPUT ip saddr 127.0.0.0/8 counter drop
add rule ip filter INPUT ip protocol tcp ct state established  counter accept
add rule ip filter INPUT ip protocol udp ct state established  counter accept
add rule ip filter INPUT ip protocol icmp ct state established  counter accept
add rule ip filter INPUT ip protocol icmp ct state related  counter accept
add rule ip filter INPUT limit rate 3/minute burst 5 packets counter log prefix "SFW2-IN-ILL-TARGET " flags tcp options flags ip options
add rule ip filter INPUT iifname "ens33" tcp flags & (fin|syn|rst|ack) != syn ct state new  limit rate 5/minute burst 7 packets counter log prefix "Drop Syn"
add rule ip filter INPUT iifname "ens33" tcp flags & (fin|syn|rst|ack) != syn ct state new  counter drop
add rule ip filter INPUT iifname "ens33" ip frag-off & 0x1fff != 0 limit rate 5/minute burst 7 packets counter log prefix "Fragments Packets"
add rule ip filter INPUT iifname "ens33" ip frag-off & 0x1fff != 0 counter drop
add rule ip filter INPUT iifname "ens33" tcp flags & (fin|syn|rst|psh|ack|urg) == fin|psh|urg counter drop
add rule ip filter INPUT iifname "ens33" tcp flags & (fin|syn|rst|psh|ack|urg) == fin|syn|rst|psh|ack|urg counter drop
add rule ip filter INPUT iifname "ens33" tcp flags & (fin|syn|rst|psh|ack|urg) == 0x0 limit rate 5/minute burst 7 packets counter log prefix "NULL Packets"
add rule ip filter INPUT iifname "ens33" tcp flags & (fin|syn|rst|psh|ack|urg) == 0x0 counter drop
add rule ip filter INPUT iifname "ens33" tcp flags & (syn|rst) == syn|rst counter drop
add rule ip filter INPUT iifname "ens33" tcp flags & (fin|syn) == fin|syn limit rate 5/minute burst 7 packets counter log prefix "XMAS Packets"
add rule ip filter INPUT iifname "ens33" tcp flags & (fin|syn) == fin|syn counter drop
add rule ip filter INPUT iifname "ens33" tcp flags & (fin|ack) == fin limit rate 5/minute burst 7 packets counter log prefix "Fin Packets Scan"
add rule ip filter INPUT iifname "ens33" tcp flags & (fin|ack) == fin counter drop
add rule ip filter INPUT iifname "ens33" tcp flags & (fin|syn|rst|psh|ack|urg) == fin|syn|rst|ack|urg counter drop
add rule ip filter INPUT iifname "ens33" tcp dport 137-139 counter reject
add rule ip filter INPUT iifname "ens33" udp dport 137-139 counter reject
add rule ip filter INPUT icmp type source-quench counter accept
add rule ip filter INPUT tcp dport 22 ct state new  counter accept
add rule ip filter INPUT udp dport 123 ct state new  counter accept
add rule ip filter INPUT udp dport 68 ct state new  counter accept
add rule ip filter INPUT tcp dport 80 ct state new  counter accept
add rule ip filter INPUT icmp type echo-request ct state new,related,established  counter accept
add rule ip filter INPUT counter log
add rule ip filter INPUT counter drop
add rule ip filter FORWARD limit rate 3/minute burst 5 packets counter log prefix "SFW2-FWD-ILL-ROUTING " flags tcp options flags ip options
add rule ip filter FORWARD counter log
add rule ip filter OUTPUT oifname "lo" counter accept
add rule ip filter OUTPUT ip protocol tcp ct state new,established  counter accept
add rule ip filter OUTPUT ip protocol udp ct state new,established  counter accept
add rule ip filter OUTPUT ip protocol icmp ct state new,established  counter accept
add rule ip filter OUTPUT icmp type echo-request counter accept
add rule ip filter OUTPUT icmp type echo-reply ct state related,established  counter accept
add rule ip filter LOGDROP counter log
add rule ip filter LOGDROP counter drop
add table ip nat
add chain ip nat PREROUTING { type nat hook prerouting priority -100; policy accept; }
add chain ip nat INPUT { type nat hook input priority 100; policy accept; }
add chain ip nat POSTROUTING { type nat hook postrouting priority 100; policy accept; }
add chain ip nat OUTPUT { type nat hook output priority -100; policy accept; }
add table ip mangle
add chain ip mangle PREROUTING { type filter hook prerouting priority -150; policy accept; }
add chain ip mangle INPUT { type filter hook input priority -150; policy accept; }
add chain ip mangle FORWARD { type filter hook forward priority -150; policy accept; }
add chain ip mangle OUTPUT { type route hook output priority -150; policy accept; }
add chain ip mangle POSTROUTING { type filter hook postrouting priority -150; policy accept; }
# Completed on Fri Jul 12 04:33:36 2019
```
You should be able to directly give this to nftables:  
```
$ sudo iptables-restore-translate -f save.txt > ruleset.nft
$ sudo nft -f ruleset.nft
```
$ sudo nft list ruleset 
List nft ruleset:
```
table ip filter {
	chain INPUT {
		type filter hook input priority 0; policy drop;
		iifname "ens33" meta l4proto tcp tcp dport 22 ct state new # recent: UPDATE seconds: 60 hit_count: 4 name: DEFAULT side: source mask: 255.255.255.255 counter packets 0 bytes 0 jump LOGDROP
		iifname "ens33" meta l4proto tcp tcp dport 22 ct state new # recent: SET name: DEFAULT side: source mask: 255.255.255.255 counter packets 0 bytes 0
		iifname "lo" counter packets 0 bytes 0 accept
		ip saddr 127.0.0.0/8 counter packets 0 bytes 0 drop
		meta l4proto tcp ct state established counter packets 487 bytes 34832 accept
		meta l4proto udp ct state established counter packets 4 bytes 1060 accept
		meta l4proto icmp ct state established counter packets 0 bytes 0 accept
		meta l4proto icmp ct state related counter packets 0 bytes 0 accept
		limit rate 3/minute counter packets 0 bytes 0 log prefix "SFW2-IN-ILL-TARGET " flags tcp options flags ip options
		iifname "ens33" meta l4proto tcp tcp flags & (fin|syn|rst|ack) != syn ct state new limit rate 5/minute burst 7 packets counter packets 0 bytes 0 log prefix "Drop Syn"
		iifname "ens33" meta l4proto tcp tcp flags & (fin|syn|rst|ack) != syn ct state new counter packets 0 bytes 0 drop
		iifname "ens33" ip frag-off & 8191 != 0 limit rate 5/minute burst 7 packets counter packets 0 bytes 0 log prefix "Fragments Packets"
		iifname "ens33" ip frag-off & 8191 != 0 counter packets 0 bytes 0 drop
		iifname "ens33" meta l4proto tcp tcp flags & (fin|syn|rst|psh|ack|urg) == fin|psh|urg counter packets 0 bytes 0 drop
		iifname "ens33" meta l4proto tcp tcp flags & (fin|syn|rst|psh|ack|urg) == fin|syn|rst|psh|ack|urg counter packets 0 bytes 0 drop
		iifname "ens33" meta l4proto tcp tcp flags & (fin|syn|rst|psh|ack|urg) == 0x0 limit rate 5/minute burst 7 packets counter packets 0 bytes 0 log prefix "NULL Packets"
		iifname "ens33" meta l4proto tcp tcp flags & (fin|syn|rst|psh|ack|urg) == 0x0 counter packets 0 bytes 0 drop
		iifname "ens33" meta l4proto tcp tcp flags & (syn|rst) == syn|rst counter packets 0 bytes 0 drop
		iifname "ens33" meta l4proto tcp tcp flags & (fin|syn) == fin|syn limit rate 5/minute burst 7 packets counter packets 0 bytes 0 log prefix "XMAS Packets"
		iifname "ens33" meta l4proto tcp tcp flags & (fin|syn) == fin|syn counter packets 0 bytes 0 drop
		iifname "ens33" meta l4proto tcp tcp flags & (fin|ack) == fin limit rate 5/minute burst 7 packets counter packets 0 bytes 0 log prefix "Fin Packets Scan"
		iifname "ens33" meta l4proto tcp tcp flags & (fin|ack) == fin counter packets 0 bytes 0 drop
		iifname "ens33" meta l4proto tcp tcp flags & (fin|syn|rst|psh|ack|urg) == fin|syn|rst|ack|urg counter packets 0 bytes 0 drop
		iifname "ens33" meta l4proto tcp tcp dport 137-139 counter packets 0 bytes 0 reject
		iifname "ens33" meta l4proto udp udp dport 137-139 counter packets 0 bytes 0 reject
		meta l4proto icmp icmp type source-quench counter packets 0 bytes 0 accept
		meta l4proto tcp tcp dport 22 ct state new counter packets 0 bytes 0 accept
		meta l4proto udp udp dport 123 ct state new counter packets 0 bytes 0 accept
		meta l4proto udp udp dport 68 ct state new counter packets 0 bytes 0 accept
		meta l4proto tcp tcp dport 80 ct state new counter packets 0 bytes 0 accept
		meta l4proto icmp icmp type echo-request ct state new,related,established counter packets 0 bytes 0 accept
		counter packets 0 bytes 0 log
		counter packets 0 bytes 0 drop
		iifname "lo" counter packets 0 bytes 0 accept
		ip saddr 127.0.0.0/8 counter packets 0 bytes 0 drop
		ip protocol tcp ct state established counter packets 0 bytes 0 accept
		ip protocol udp ct state established counter packets 0 bytes 0 accept
		ip protocol icmp ct state established counter packets 0 bytes 0 accept
		ip protocol icmp ct state related counter packets 0 bytes 0 accept
		limit rate 3/minute counter packets 0 bytes 0 log prefix "SFW2-IN-ILL-TARGET " flags tcp options flags ip options
		iifname "ens33" tcp flags & (fin | syn | rst | ack) != syn ct state new limit rate 5/minute burst 7 packets counter packets 0 bytes 0 log prefix "Drop Syn"
		iifname "ens33" tcp flags & (fin | syn | rst | ack) != syn ct state new counter packets 0 bytes 0 drop
		iifname "ens33" ip frag-off & 8191 != 0 limit rate 5/minute burst 7 packets counter packets 0 bytes 0 log prefix "Fragments Packets"
		iifname "ens33" ip frag-off & 8191 != 0 counter packets 0 bytes 0 drop
		iifname "ens33" tcp flags & (fin | syn | rst | psh | ack | urg) == fin | psh | urg counter packets 0 bytes 0 drop
		iifname "ens33" tcp flags & (fin | syn | rst | psh | ack | urg) == fin | syn | rst | psh | ack | urg counter packets 0 bytes 0 drop
		iifname "ens33" tcp flags & (fin | syn | rst | psh | ack | urg) == 0x0 limit rate 5/minute burst 7 packets counter packets 0 bytes 0 log prefix "NULL Packets"
		iifname "ens33" tcp flags & (fin | syn | rst | psh | ack | urg) == 0x0 counter packets 0 bytes 0 drop
		iifname "ens33" tcp flags & (syn | rst) == syn | rst counter packets 0 bytes 0 drop
		iifname "ens33" tcp flags & (fin | syn) == fin | syn limit rate 5/minute burst 7 packets counter packets 0 bytes 0 log prefix "XMAS Packets"
		iifname "ens33" tcp flags & (fin | syn) == fin | syn counter packets 0 bytes 0 drop
		iifname "ens33" tcp flags & (fin | ack) == fin limit rate 5/minute burst 7 packets counter packets 0 bytes 0 log prefix "Fin Packets Scan"
		iifname "ens33" tcp flags & (fin | ack) == fin counter packets 0 bytes 0 drop
		iifname "ens33" tcp flags & (fin | syn | rst | psh | ack | urg) == fin | syn | rst | ack | urg counter packets 0 bytes 0 drop
		iifname "ens33" tcp dport 137-139 counter packets 0 bytes 0 reject
		iifname "ens33" udp dport 137-139 counter packets 0 bytes 0 reject
		icmp type source-quench counter packets 0 bytes 0 accept
		tcp dport ssh ct state new counter packets 0 bytes 0 accept
		udp dport ntp ct state new counter packets 0 bytes 0 accept
		udp dport bootpc ct state new counter packets 0 bytes 0 accept
		tcp dport http ct state new counter packets 0 bytes 0 accept
		icmp type echo-request ct state established,related,new counter packets 0 bytes 0 accept
		counter packets 0 bytes 0 log
		counter packets 0 bytes 0 drop
	}

	chain FORWARD {
		type filter hook forward priority 0; policy drop;
		# PHYSDEV match --physdev-is-bridged counter packets 0 bytes 0 accept
		limit rate 3/minute counter packets 0 bytes 0 log prefix "SFW2-FWD-ILL-ROUTING " flags tcp options flags ip options
		counter packets 0 bytes 0 log
		limit rate 3/minute counter packets 0 bytes 0 log prefix "SFW2-FWD-ILL-ROUTING " flags tcp options flags ip options
		counter packets 0 bytes 0 log
	}

	chain OUTPUT {
		type filter hook output priority 0; policy drop;
		oifname "lo" counter packets 0 bytes 0 accept
		meta l4proto tcp ct state new,established counter packets 308 bytes 44704 accept
		meta l4proto udp ct state new,established counter packets 4 bytes 1060 accept
		meta l4proto icmp ct state new,established counter packets 0 bytes 0 accept
		meta l4proto icmp icmp type echo-request counter packets 0 bytes 0 accept
		meta l4proto icmp icmp type echo-reply ct state related,established counter packets 0 bytes 0 accept
		oifname "lo" counter packets 0 bytes 0 accept
		ip protocol tcp ct state established,new counter packets 0 bytes 0 accept
		ip protocol udp ct state established,new counter packets 0 bytes 0 accept
		ip protocol icmp ct state established,new counter packets 0 bytes 0 accept
		icmp type echo-request counter packets 0 bytes 0 accept
		icmp type echo-reply ct state established,related counter packets 0 bytes 0 accept
	}

	chain LOGDROP {
		counter packets 0 bytes 0 log
		counter packets 0 bytes 0 drop
		counter packets 0 bytes 0 log
		counter packets 0 bytes 0 drop
	}
}
table ip nat {
	chain PREROUTING {
		type nat hook prerouting priority -100; policy accept;
	}

	chain INPUT {
		type nat hook input priority 100; policy accept;
	}

	chain POSTROUTING {
		type nat hook postrouting priority 100; policy accept;
	}

	chain OUTPUT {
		type nat hook output priority -100; policy accept;
	}
}
table ip mangle {
	chain PREROUTING {
		type filter hook prerouting priority -150; policy accept;
	}

	chain INPUT {
		type filter hook input priority -150; policy accept;
	}

	chain FORWARD {
		type filter hook forward priority -150; policy accept;
	}

	chain OUTPUT {
		type route hook output priority -150; policy accept;
	}

	chain POSTROUTING {
		type filter hook postrouting priority -150; policy accept;
	}
}
```

## Uninstall iptables 
```
$ sudo apt purge --autoremove iptables 
```

## Reference  
[https://wiki.debian.org/nftables](https://wiki.debian.org/nftables)   
[https://wiki.nftables.org/wiki-nftables/index.php/Moving_from_iptables_to_nftables](https://wiki.nftables.org/wiki-nftables/index.php/Moving_from_iptables_to_nftables)  
