# =========================
# MIKROTIK PUSAT - FINAL (PRODUCTION TEMPLATE)
# RouterOS v7+
# =========================
#
# Topology assumptions:
# - ISP2 has static public IP and is the VPN hub entrypoint
# - Branches are dynamic/CGNAT and initiate tunnels to HQ
# - Ubuntu GenieACS server is behind MikroTik at 172.16.27.26
#
# Fill all placeholders before import.

# ==== REQUIRED VARIABLES ====
:local WAN_IF "ether1-ISP2"
:local LAN_IF "bridge-lan"
:local UBUNTU_IP "172.16.27.26"
:local MGMT_IP "172.16.27.100"

:local WG_IF "wg-core-hub"
:local WG_PORT 51820
:local HUB_PRIVKEY "PASTE_HUB_PRIVATE_KEY"
:local CBG_CINDE_PUBKEY "PASTE_CINDE_PUBLIC_KEY"

# Transit WG /30 dedicated per branch (no overlap)
:local HUB_WG_IP "10.250.50.1/30"
:local CBG_CINDE_WG_HOST "10.250.50.2/32"

# Branch CINDE local subnets
:local CBG_NET1 "10.10.50.0/23"
:local CBG_NET2 "192.168.55.0/24"
:local CBG_NET3 "192.168.50.0/24"
:local CBG_NET4 "10.140.50.0/24"
:local CBG_NET5 "10.12.50.0/23"
:local CBG_NET6 "172.16.50.0/24"
:local CBG_NET7 "192.168.8.0/24"

# ==== INTERFACE LISTS ====
/interface/list/add name=WAN
/interface/list/add name=LAN
/interface/list/member/add list=WAN interface=$WAN_IF
/interface/list/member/add list=LAN interface=$LAN_IF

# ==== WIREGUARD HUB ====
/interface/wireguard/add name=$WG_IF listen-port=$WG_PORT private-key=$HUB_PRIVKEY mtu=1420
/ip/address/add address=$HUB_WG_IP interface=$WG_IF

/interface/wireguard/peers/add interface=$WG_IF public-key=$CBG_CINDE_PUBKEY \
allowed-address=$CBG_CINDE_WG_HOST,$CBG_NET1,$CBG_NET2,$CBG_NET3,$CBG_NET4,$CBG_NET5,$CBG_NET6,$CBG_NET7 \
persistent-keepalive=25s comment="CINDE"

# ==== ROUTES TO BRANCH ====
/ip/route/add dst-address=$CBG_NET1 gateway=$WG_IF comment="to CINDE 10.10.50.0/23"
/ip/route/add dst-address=$CBG_NET2 gateway=$WG_IF comment="to CINDE 192.168.55.0/24"
/ip/route/add dst-address=$CBG_NET3 gateway=$WG_IF comment="to CINDE 192.168.50.0/24"
/ip/route/add dst-address=$CBG_NET4 gateway=$WG_IF comment="to CINDE 10.140.50.0/24"
/ip/route/add dst-address=$CBG_NET5 gateway=$WG_IF comment="to CINDE 10.12.50.0/23"
/ip/route/add dst-address=$CBG_NET6 gateway=$WG_IF comment="to CINDE 172.16.50.0/24"
/ip/route/add dst-address=$CBG_NET7 gateway=$WG_IF comment="to CINDE 192.168.8.0/24"

# ==== FIREWALL INPUT ====
/ip/firewall/filter/add chain=input action=accept connection-state=established,related,untracked comment="allow established"
/ip/firewall/filter/add chain=input action=drop connection-state=invalid comment="drop invalid"
/ip/firewall/filter/add chain=input action=accept protocol=udp dst-port=$WG_PORT in-interface=$WAN_IF comment="allow WG hub"
/ip/firewall/filter/add chain=input action=accept src-address=$MGMT_IP comment="allow HQ mgmt laptop"
/ip/firewall/filter/add chain=input action=accept protocol=icmp limit=20,20:packet comment="limited ping"
/ip/firewall/filter/add chain=input action=drop in-interface-list=WAN comment="drop remaining WAN input"

# ==== FIREWALL FORWARD ====
/ip/firewall/filter/add chain=forward action=accept connection-state=established,related,untracked comment="allow established"
/ip/firewall/filter/add chain=forward action=drop connection-state=invalid comment="drop invalid"

# Branch -> HQ server LAN
/ip/firewall/filter/add chain=forward action=accept src-address=$CBG_NET1 dst-address=172.16.27.0/24
/ip/firewall/filter/add chain=forward action=accept src-address=$CBG_NET2 dst-address=172.16.27.0/24
/ip/firewall/filter/add chain=forward action=accept src-address=$CBG_NET3 dst-address=172.16.27.0/24
/ip/firewall/filter/add chain=forward action=accept src-address=$CBG_NET4 dst-address=172.16.27.0/24
/ip/firewall/filter/add chain=forward action=accept src-address=$CBG_NET5 dst-address=172.16.27.0/24
/ip/firewall/filter/add chain=forward action=accept src-address=$CBG_NET6 dst-address=172.16.27.0/24
/ip/firewall/filter/add chain=forward action=accept src-address=$CBG_NET7 dst-address=172.16.27.0/24

# HQ server LAN -> Branch
/ip/firewall/filter/add chain=forward action=accept src-address=172.16.27.0/24 dst-address=$CBG_NET1
/ip/firewall/filter/add chain=forward action=accept src-address=172.16.27.0/24 dst-address=$CBG_NET2
/ip/firewall/filter/add chain=forward action=accept src-address=172.16.27.0/24 dst-address=$CBG_NET3
/ip/firewall/filter/add chain=forward action=accept src-address=172.16.27.0/24 dst-address=$CBG_NET4
/ip/firewall/filter/add chain=forward action=accept src-address=172.16.27.0/24 dst-address=$CBG_NET5
/ip/firewall/filter/add chain=forward action=accept src-address=172.16.27.0/24 dst-address=$CBG_NET6
/ip/firewall/filter/add chain=forward action=accept src-address=172.16.27.0/24 dst-address=$CBG_NET7

# default deny
/ip/firewall/filter/add chain=forward action=drop comment="default drop forward"

# ==== NAT ====
# bypass NAT for site-to-site traffic
/ip/firewall/nat/add chain=srcnat action=accept src-address=172.16.27.0/24 dst-address=$CBG_NET1
/ip/firewall/nat/add chain=srcnat action=accept src-address=172.16.27.0/24 dst-address=$CBG_NET2
/ip/firewall/nat/add chain=srcnat action=accept src-address=172.16.27.0/24 dst-address=$CBG_NET3
/ip/firewall/nat/add chain=srcnat action=accept src-address=172.16.27.0/24 dst-address=$CBG_NET4
/ip/firewall/nat/add chain=srcnat action=accept src-address=172.16.27.0/24 dst-address=$CBG_NET5
/ip/firewall/nat/add chain=srcnat action=accept src-address=172.16.27.0/24 dst-address=$CBG_NET6
/ip/firewall/nat/add chain=srcnat action=accept src-address=172.16.27.0/24 dst-address=$CBG_NET7

# internet NAT
/ip/firewall/nat/add chain=srcnat action=masquerade out-interface-list=WAN comment="internet NAT"

# ==== PORT FORWARD TO UBUNTU ====
# Public HTTPS for UI/API gateway
/ip/firewall/nat/add chain=dstnat action=dst-nat protocol=tcp in-interface=$WAN_IF dst-port=443 to-addresses=$UBUNTU_IP to-ports=443 comment="HTTPS -> Ubuntu"
# Public CWMP TLS endpoint
/ip/firewall/nat/add chain=dstnat action=dst-nat protocol=tcp in-interface=$WAN_IF dst-port=7547 to-addresses=$UBUNTU_IP to-ports=7547 comment="CWMP TLS -> Ubuntu"
