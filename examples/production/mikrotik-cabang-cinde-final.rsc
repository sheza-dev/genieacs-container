# =========================
# MIKROTIK CABANG CINDE - FINAL (PRODUCTION TEMPLATE)
# RouterOS v7+
# =========================
#
# Branch is behind dynamic public / CGNAT and must initiate tunnel to HQ.

# ==== REQUIRED VARIABLES ====
:local WAN_IF "ether1"
:local WG_IF "wg-core-cinde"
:local CBG_PRIVKEY "PASTE_CINDE_PRIVATE_KEY"
:local HUB_PUBKEY "PASTE_HUB_PUBLIC_KEY"

# HQ static public IP (ISP2)
:local HUB_ENDPOINT "X.X.X.X"
:local HUB_PORT 51820

# WG transit /30 dedicated
:local CBG_WG_IP "10.250.50.2/30"
:local HUB_WG_HOST "10.250.50.1/32"

# HQ accessible networks
:local HQ_NET1 "172.16.27.0/24"
:local HQ_NET2 "10.100.27.0/24"

# CINDE local networks
:local CBG_NET1 "10.10.50.0/23"
:local CBG_NET2 "192.168.55.0/24"
:local CBG_NET3 "192.168.50.0/24"
:local CBG_NET4 "10.140.50.0/24"
:local CBG_NET5 "10.12.50.0/23"
:local CBG_NET6 "172.16.50.0/24"
:local CBG_NET7 "192.168.8.0/24"

# ==== WG SPOKE ====
/interface/wireguard/add name=$WG_IF private-key=$CBG_PRIVKEY listen-port=51820 mtu=1420
/ip/address/add address=$CBG_WG_IP interface=$WG_IF

/interface/wireguard/peers/add interface=$WG_IF public-key=$HUB_PUBKEY \
endpoint-address=$HUB_ENDPOINT endpoint-port=$HUB_PORT \
allowed-address=$HUB_WG_HOST,$HQ_NET1,$HQ_NET2 persistent-keepalive=25s comment="HQ Hub"

# ==== ROUTES TO HQ ====
/ip/route/add dst-address=$HQ_NET1 gateway=$WG_IF
/ip/route/add dst-address=$HQ_NET2 gateway=$WG_IF

# ==== FIREWALL INPUT ====
/ip/firewall/filter/add chain=input action=accept connection-state=established,related,untracked comment="allow established"
/ip/firewall/filter/add chain=input action=drop connection-state=invalid comment="drop invalid"
/ip/firewall/filter/add chain=input action=accept src-address=192.168.50.0/24 comment="allow branch management LAN"
/ip/firewall/filter/add chain=input action=drop in-interface=$WAN_IF comment="drop WAN input"

# ==== FIREWALL FORWARD ====
/ip/firewall/filter/add chain=forward action=accept connection-state=established,related,untracked comment="allow established"
/ip/firewall/filter/add chain=forward action=drop connection-state=invalid comment="drop invalid"

# Allow branch users/services to HQ server LAN
/ip/firewall/filter/add chain=forward action=accept src-address=$CBG_NET1 dst-address=$HQ_NET1
/ip/firewall/filter/add chain=forward action=accept src-address=$CBG_NET2 dst-address=$HQ_NET1
/ip/firewall/filter/add chain=forward action=accept src-address=$CBG_NET3 dst-address=$HQ_NET1
/ip/firewall/filter/add chain=forward action=accept src-address=$CBG_NET4 dst-address=$HQ_NET1
/ip/firewall/filter/add chain=forward action=accept src-address=$CBG_NET5 dst-address=$HQ_NET1
/ip/firewall/filter/add chain=forward action=accept src-address=$CBG_NET6 dst-address=$HQ_NET1
/ip/firewall/filter/add chain=forward action=accept src-address=$CBG_NET7 dst-address=$HQ_NET1

# Allow to HQ ONU VLAN path if needed
/ip/firewall/filter/add chain=forward action=accept src-address=$CBG_NET1 dst-address=$HQ_NET2
/ip/firewall/filter/add chain=forward action=accept src-address=$CBG_NET2 dst-address=$HQ_NET2
/ip/firewall/filter/add chain=forward action=accept src-address=$CBG_NET3 dst-address=$HQ_NET2
/ip/firewall/filter/add chain=forward action=accept src-address=$CBG_NET4 dst-address=$HQ_NET2
/ip/firewall/filter/add chain=forward action=accept src-address=$CBG_NET5 dst-address=$HQ_NET2
/ip/firewall/filter/add chain=forward action=accept src-address=$CBG_NET6 dst-address=$HQ_NET2
/ip/firewall/filter/add chain=forward action=accept src-address=$CBG_NET7 dst-address=$HQ_NET2

/ip/firewall/filter/add chain=forward action=drop comment="default drop forward"

# ==== NAT ====
# bypass NAT to HQ networks
/ip/firewall/nat/add chain=srcnat action=accept src-address=$CBG_NET1 dst-address=$HQ_NET1
/ip/firewall/nat/add chain=srcnat action=accept src-address=$CBG_NET2 dst-address=$HQ_NET1
/ip/firewall/nat/add chain=srcnat action=accept src-address=$CBG_NET3 dst-address=$HQ_NET1
/ip/firewall/nat/add chain=srcnat action=accept src-address=$CBG_NET4 dst-address=$HQ_NET1
/ip/firewall/nat/add chain=srcnat action=accept src-address=$CBG_NET5 dst-address=$HQ_NET1
/ip/firewall/nat/add chain=srcnat action=accept src-address=$CBG_NET6 dst-address=$HQ_NET1
/ip/firewall/nat/add chain=srcnat action=accept src-address=$CBG_NET7 dst-address=$HQ_NET1

/ip/firewall/nat/add chain=srcnat action=accept src-address=$CBG_NET1 dst-address=$HQ_NET2
/ip/firewall/nat/add chain=srcnat action=accept src-address=$CBG_NET2 dst-address=$HQ_NET2
/ip/firewall/nat/add chain=srcnat action=accept src-address=$CBG_NET3 dst-address=$HQ_NET2
/ip/firewall/nat/add chain=srcnat action=accept src-address=$CBG_NET4 dst-address=$HQ_NET2
/ip/firewall/nat/add chain=srcnat action=accept src-address=$CBG_NET5 dst-address=$HQ_NET2
/ip/firewall/nat/add chain=srcnat action=accept src-address=$CBG_NET6 dst-address=$HQ_NET2
/ip/firewall/nat/add chain=srcnat action=accept src-address=$CBG_NET7 dst-address=$HQ_NET2

# internet NAT
/ip/firewall/nat/add chain=srcnat action=masquerade out-interface=$WAN_IF comment="internet NAT"
