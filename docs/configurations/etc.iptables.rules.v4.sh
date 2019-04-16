#!/bin/bash
IPT="/sbin/iptables"
 
 echo "Starting IPv4 Wall..."
 $IPT -F
 $IPT -X
 $IPT -t nat -F
 $IPT -t nat -X
 $IPT -t mangle -F
 $IPT -t mangle -X
 $IPT -N LOGDROP
 modprobe ip_conntrack
  
PUB_IFS="ens33"
   
#unlimited 
$IPT -A INPUT -i lo -j ACCEPT
$IPT -A OUTPUT -o lo -j ACCEPT
# DROP all incomming traffic
$IPT -P INPUT DROP
$IPT -P OUTPUT DROP
$IPT -P FORWARD DROP

$IPT -A INPUT -i lo -j ACCEPT
$IPT -A OUTPUT -o lo -j ACCEPT
$IPT -A INPUT -s 127.0.0.0/8 -j DROP

$IPT -A OUTPUT -p tcp -m state --state NEW,ESTABLISHED -j ACCEPT
$IPT -A OUTPUT -p udp -m state --state NEW,ESTABLISHED -j ACCEPT
$IPT -A OUTPUT -p icmp -m state --state NEW,ESTABLISHED -j ACCEPT
$IPT -A INPUT -p tcp -m state --state ESTABLISHED -j ACCEPT
$IPT -A INPUT -p udp -m state --state ESTABLISHED -j ACCEPT
$IPT -A INPUT -p icmp -m state --state ESTABLISHED -j ACCEPT
$IPT -A INPUT -p icmp -m state --state RELATED -j ACCEPT


$IPT -A INPUT -m limit --limit 3/min -j LOG --log-prefix "SFW2-IN-ILL-TARGET " --log-tcp-options --log-ip-options
$IPT -A FORWARD -m physdev --physdev-is-bridged -j ACCEPT
$IPT -A FORWARD -m limit --limit 3/min -j LOG --log-prefix "SFW2-FWD-ILL-ROUTING " --log-tcp-options --log-ip-options

for PUB_IF in $PUB_IFS
do 
# sync
    $IPT -A INPUT -i ${PUB_IF} -p tcp ! --syn -m state --state NEW  -m limit --limit 5/m --limit-burst 7 -j LOG --log-level 4 --log-prefix "Drop Syn"     
    $IPT -A INPUT -i ${PUB_IF} -p tcp ! --syn -m state --state NEW -j DROP
           
# Fragments
    $IPT -A INPUT -i ${PUB_IF} -f  -m limit --limit 5/m --limit-burst 7 -j LOG --log-level 4 --log-prefix "Fragments Packets"
    $IPT -A INPUT -i ${PUB_IF} -f -j DROP
            
             
# block bad stuff
    $IPT  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP
    $IPT  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags ALL ALL -j DROP
              
    $IPT  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags ALL NONE -m limit --limit 5/m --limit-burst 7 -j LOG --log-level 4 --log-prefix "NULL Packets"
    $IPT  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags ALL NONE -j DROP # NULL packets
               
    $IPT  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
                
    $IPT  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags SYN,FIN SYN,FIN -m limit --limit 5/m --limit-burst 7 -j LOG --log-level 4 --log-prefix "XMAS Packets"
    $IPT  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP #XMAS
                 
    $IPT  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags FIN,ACK FIN -m limit --limit 5/m --limit-burst 7 -j LOG --log-level 4 --log-prefix "Fin Packets Scan"
    $IPT  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags FIN,ACK FIN -j DROP # FIN packet scans
                  
    $IPT  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP
                   
    # No smb/windows sharing packets - too much logging
    $IPT -A INPUT -p tcp -i ${PUB_IF} --dport 137:139 -j REJECT
    $IPT -A INPUT -p udp -i ${PUB_IF} --dport 137:139 -j REJECT
    $IPT -I INPUT -p tcp --dport 22 -i ${PUB_IF} -m state --state NEW -m recent --set
    $IPT -I INPUT -p tcp --dport 22 -i ${PUB_IF} -m state --state NEW -m recent  --update --seconds 60 --hitcount 4 -j LOGDROP
 done
    # Allow full outgoing connection but no incomming stuff
    $IPT -A INPUT -p icmp -m icmp --icmp-type 4 -j ACCEPT
    $IPT -A OUTPUT -p icmp -m icmp --icmp-type 8 -j ACCEPT

    # allow ssh/http/ntp/dhclint only
    $IPT -A INPUT -p tcp --dport 22 -m state --state NEW -j ACCEPT
    $IPT -A INPUT -p udp --dport 123 -m state --state NEW -j ACCEPT
    $IPT -A INPUT -p udp --dport 68 -m state --state NEW -j ACCEPT
    ip6tables -A INPUT -p udp --dport 123 -m state --state NEW -j ACCEPT
#    $IPT -A INPUT -p tcp --dport 80 -m state --state NEW -j ACCEPT
#    $IPT -A INPUT -p tcp --dport 443 -m state --state NEW -j ACCEPT
 
    # allow incoming ICMP ping pong stuff
    $IPT -A INPUT -p icmp --icmp-type 8 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
    $IPT -A OUTPUT -p icmp --icmp-type 0 -m state --state ESTABLISHED,RELATED -j ACCEPT
     
    # prevent ssh brute force attack
    $IPT -A LOGDROP -j LOG
    $IPT -A LOGDROP -j DROP

# Log everything else
# *** Required for psad ****
$IPT -A INPUT -j LOG
$IPT -A FORWARD -j LOG
$IPT -A INPUT -j DROP
 
exit 0
