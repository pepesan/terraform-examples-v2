#!/bin/bash
source .env
set -eux
# install kernel modules
dnf install -y kernel-modules

# check loaded kernel module dependencies
for module in br_netfilter ip6_udp_tunnel ip_set ip_set_hash_ip ip_set_hash_net iptable_filter iptable_nat iptable_mangle iptable_raw nf_conntrack_netlink nf_conntrack nf_conntrack_ipv4   nf_defrag_ipv4 nf_nat nf_nat_ipv4 nf_nat_masquerade_ipv4 nfnetlink udp_tunnel veth vxlan x_tables xt_addrtype xt_conntrack xt_comment xt_mark xt_multiport xt_nat xt_recent xt_set  xt_statistic xt_tcpudp;
     do
       if ! lsmod | grep -q $module; then
         echo "module $module is not present";
       fi;
       modprobe $module;
done
# loading k8s kernel module dependencies
for module in br_netfilter ip6_udp_tunnel ip_set ip_set_hash_ip ip_set_hash_net iptable_filter iptable_nat iptable_mangle iptable_raw nf_conntrack_netlink nf_conntrack nf_conntrack_ipv4 nf_defrag_ipv4 nf_nat nf_nat_ipv4 nf_nat_masquerade_ipv4 nfnetlink udp_tunnel veth vxlan x_tables xt_addrtype xt_conntrack xt_comment xt_mark xt_multiport xt_nat xt_recent xt_set xt_statistic xt_tcpudp;
  do
  modprobe $module;
done
# load kernel modules on startup
echo -e 'br_netfilter\nip6_udp_tunnel\nip_set\nip_set_hash_ip\nip_set_hash_net\niptable_filter\niptable_nat\niptable_mangle\niptable_raw\nnf_conntrack_netlink\nnf_conntrack\nnf_conntrack_ipv4\nnf_defrag_ipv4\nnf_nat\nnf_nat_ipv4\nnf_nat_masquerade_ipv4\nnfnetlink\nudp_tunnel\nveth\nvxlan\nx_tables\nxt_addrtype\nxt_conntrack\nxt_comment\nxt_mark\nxt_multiport\nxt_nat\nxt_recent\nxt_set\nxt_statistic\nxt_tcpudp' > /etc/modules-load.d/rke.conf
# configure kernel to manage iptables and ip forward
echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.d/rke.conf
echo "net.bridge.bridge-nf-call-ip6tables = 1" >> /etc/sysctl.d/rke.conf
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.d/rke.conf
sysctl -p /etc/sysctl.d/rke.conf