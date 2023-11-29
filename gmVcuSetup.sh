#!/bin/bash
# Copyright (C) 2020 Continental Automotive Systems, Inc., all rights reserved
# set -u  # exit on undeclared variable usage
set -e  # exit on error

VERSION=1.0
PROGNAME="$(basename $0)"

usage() {

    echo "$PROGNAME $VERSION"
    cat << EOF

Usage:
    $PROGNAME <options>

Options:
    -h, --help                      Show this help
    --version                       Print version number

  VCU Options:
    -V <variant>                    Indicate VCU variant:
                                    low  - Low hardware variant configuration.
                                    high - High hardware variant configuration.
                                    If this is not indicated, default variant will be high.

  VLAN Options:
    -i <interface>                  Ethernet interface to create vcu VLANs: 2,4,5,43,44,45 and 46
    -gw <vlan_id>                   Default gateway and DNS server will be set according to vlan_id.
                                    vlan_id shall be from Infotainment only: 43, 44, 45, 46.
                                    If this is not indicated, default vlan_id will be 46.

    -6                              Enable IPv6 support.
    --no4                           Disable IPv4 Internet (not forwarding IPv4)
                                    Usually used with '-6'
    
    --dns <ip>|<port>|<ip:port>     DNS server's upstream DNS.
                                    Use ',' to seperate multiple servers
                                    (default: use /etc/resolve.conf)
                                    (Note IPv6 addresses need '[]' around)
    --arp                           Enable ARP on VLANs

  WiFi hotspot options:
    --ap <wifi interface>           WLAN interface name to create vcu hotspot interface.

    --ssid                          ssid name of wifi hotspot.
                                    If this is not indicated, default ssid will be VCUHotspot.

    -p, --password <password>       WiFi password
                                    If this is not indicated, default pass will be 123456789.

    -b <vlan_id>                    Backhaul vlanid interface for wifi tethering.
                                    If this is not indicated, default vlan_id will be 46.


Examples:
    Creating only VLANs:
    $PROGNAME -i eth0
    $PROGNAME -V low -i eth0 -gw 45

    Creating only VLANs with IPv6 support
    $PROGNAME -i eth0 -6
    $PROGNAME -i eth0 -6 --no4

    Creating VLANs and WIFI Hotspot
    $PROGNAME -i eth0 --ap wlan0 VCUHotspot -p 123456789
    $PROGNAME -i eth0 -gw 43 --ap wlan0 VCUHotspot -p 123456789 -b 45

    Creating VLANs and WIFI Hotspot with IPv6 support
    $PROGNAME -i eth0 --ap wlan0 VCUHotspot -p 123456789 -6
    $PROGNAME -i eth0 --ap wlan0 VCUHotspot -p 123456789 -6 --no4

EOF
}

check_empty_option(){
    if [[ "$1" == "" ]]; then
        usage
        exit 0
    fi
}

define_global_variables(){

    # Options variables

    VCU_VARIANT=high
    VCU_IFACE=                  # Ethernet interface to create vcu VLANs: 2,4,5,43,44,45 and 46
    GATEWAY=46                  # Default gateway and DNS server will be set according to vlan_id.
    IPV6=0                      # Enable IPv6 support.
    NO4=0                       # Disable IPv4 Internet (not forwarding IPv4)
    ARP=0                       # Enable ARP on VLANs

    WIFI_IFACE=                 # Wifi interface
    SSID=VCUHotspot
    PASSPHRASE=123456789
    BACKHAUL_IF=45              # Backhaul vlanid interface for wifi tethering

    # GM VCU variables
    # TCU
    TCU_MAC_ADDR=02:04:00:00:02:00

    TCU_VLAN4_IPV4_ADDR=172.16.4.1
    TCU_VLAN5_IPV4_ADDR=172.16.5.102
    TCU_VLAN43_IPV4_ADDR=172.16.43.102
    TCU_VLAN44_IPV4_ADDR=172.16.44.102
    TCU_VLAN45_IPV4_ADDR=172.16.45.102
    TCU_VLAN46_IPV4_ADDR=172.16.46.102

    TCU_LINK_IPV6_ADDR=fe80::4:ff:fe00:200

    TCU_VLAN43_IPV6_ADDR=fd53:7cb8:383:2b::1
    TCU_VLAN44_IPV6_ADDR=fd53:7cb8:383:2c::1
    TCU_VLAN45_IPV6_ADDR=fd53:7cb8:383:2d::1
    TCU_VLAN46_IPV6_ADDR=fd53:7cb8:383:2e::1

    #VCU
    # High Variant
    VCU_HV_VLAN4_MAC_ADDR=02:04:00:00:01:00
    VCU_HV_VLAN5_MAC_ADDR=02:04:00:00:01:05
    VCU_HV_VLAN43_MAC_ADDR=02:04:00:00:01:43
    VCU_HV_VLAN44_MAC_ADDR=02:04:00:00:01:44
    VCU_HV_VLAN45_MAC_ADDR=02:04:00:00:01:45
    VCU_HV_VLAN46_MAC_ADDR=02:04:00:00:01:46

    VCU_HV_VLAN4_IPV4_ADDR=172.16.4.100
    VCU_HV_VLAN5_IPV4_ADDR=172.16.5.100
    VCU_HV_VLAN43_IPV4_ADDR=172.16.43.100
    VCU_HV_VLAN44_IPV4_ADDR=172.16.44.100
    VCU_HV_VLAN45_IPV4_ADDR=172.16.45.100
    VCU_HV_VLAN46_IPV4_ADDR=172.16.46.100

    # Low Variant
    VCU_LV_VLAN4_MAC_ADDR=02:04:00:00:07:00
    VCU_LV_VLAN5_MAC_ADDR=02:04:00:00:07:00
    VCU_LV_VLAN43_MAC_ADDR=02:04:00:00:07:00
    VCU_LV_VLAN44_MAC_ADDR=02:04:00:00:07:00
    VCU_LV_VLAN45_MAC_ADDR=02:04:00:00:07:00
    VCU_LV_VLAN46_MAC_ADDR=02:04:00:00:07:00

    VCU_LV_VLAN4_IPV4_ADDR=172.16.4.108
    VCU_LV_VLAN5_IPV4_ADDR=172.16.5.108
    VCU_LV_VLAN43_IPV4_ADDR=172.16.43.108
    VCU_LV_VLAN44_IPV4_ADDR=172.16.44.108
    VCU_LV_VLAN45_IPV4_ADDR=172.16.45.108
    VCU_LV_VLAN46_IPV4_ADDR=172.16.46.108
}

parse_user_options(){
    while [[ -n "$1" ]]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            --version)
                echo "$VERSION"
                exit 0
                ;;
            -V)
                shift
                VCU_VARIANT="$1"
                ;;
            -i)
                shift
                VCU_IFACE="$1"
                ;;
            -gw)
                shift
                GATEWAY="$1"
                ;;
            -6)
                IPV6=1
                ;;
            --no4)
                NO4=1
                ;;
            --arp)
                ARP=1
                ;;
            --ap)
                shift
                WIFI_IFACE="$1"
                ;;
            --ssid)
                shift
                SSID="$1"
                ;;
            -p|--password)
                shift
                PASSPHRASE="$1"
                ;;
            -b)
                shift
                BACKHAUL_IF="$1"
                ;;
        *)
            echo  "Invalid parameter: $1" 1>&2
            exit 1
            ;;
        esac
        shift
    done
}

check_options_conflict() {

    if [[ $IPV6 -eq 0 && $NO4 -eq 1 ]]; then
        echo "Error: --no4 is usually used with '-6'"
        echo
        exit 1
    fi
}

set_vlan() {

    local iface=$1
    local vlan_id=$2
    local ipv4_host_addr=$3    
    local mac_host_addr=$4
    local ipv4_gw_addr=$5
    local mac_gw_addr=$6
    local ipv4_prefix_size=24

    # Delete VLAN
    ip link del ${iface}.${vlan_id} 2> /dev/null || true

    # Create VLAN
    ip link add link ${iface} name ${iface}.${vlan_id} type vlan id ${vlan_id}
    ip link set ${iface}.${vlan_id} address ${mac_host_addr}    
    
    if [[ $NO4 -eq 0 ]]; then
        ip addr add ${ipv4_host_addr}/${ipv4_prefix_size} dev ${iface}.${vlan_id}
        echo "VLAN created: ${iface}.${vlan_id}: ${ipv4_host_addr}: ${mac_host_addr}"
    else
        echo "VLAN created: ${iface}.${vlan_id}: NO4: ${mac_host_addr}"
    fi

    if [[ $ARP -eq 0  && $NO4 -eq 0 ]]; then
        # Disable ARP
        # Use ebtables to disable ARP only for IPv4

        # Add corresponding bridge ARP entry
        ip -4 neigh replace ${ipv4_gw_addr} lladdr ${mac_gw_addr} dev ${iface}.${vlan_id}
        echo "VLAN neigh entry added: ${iface}.${vlan_id}: ${ipv4_gw_addr}: ${mac_gw_addr}"
    fi

    # Bring VLAN up
    ip link set dev ${iface}.${vlan_id} up

    if [[ $NO4 -eq 0 ]]; then

        # Add rule policy for VLAN
        ip route flush table ${vlan_id} 2> /dev/null || true
        ip rule del from ${ipv4_host_addr} table ${vlan_id} 2> /dev/null || true
        ip route add default via ${ipv4_gw_addr} dev ${iface}.${vlan_id} table ${vlan_id}
        ip rule add from ${ipv4_host_addr} table ${vlan_id}
        echo "VLAN rule policy added: default via ${ipv4_gw_addr} dev ${iface}.${vlan_id} table ${vlan_id}"
        echo
    fi
}

flush_all_neigh_entries(){

    if [[ $NO4 -eq 0 ]]; then
        ip -4 neigh flush all
        echo "Flush all IPv4 neigh entries"
    fi

    if [[ $IPV6 -eq 1 ]]; then
        ip -6 neigh flush all
        echo "Flush all IPv6 neigh entries"
    fi
    echo
}

create_vcu_vlans() {
    
    local vcu_vlan4_mac_addr
    local vcu_vlan5_mac_addr
    local vcu_vlan43_mac_addr
    local vcu_vlan44_mac_addr
    local vcu_vlan45_mac_addr
    local vcu_vlan46_mac_addr

    local vcu_vlan4_ipv4_addr
    local vcu_vlan5_ipv4_addr
    local vcu_vlan43_ipv4_addr
    local vcu_vlan44_ipv4_addr
    local vcu_vlan45_ipv4_addr
    local vcu_vlan46_ipv4_addr

    case "${VCU_VARIANT}" in

        high)
            vcu_vlan4_mac_addr=${VCU_HV_VLAN4_MAC_ADDR}
            vcu_vlan5_mac_addr=${VCU_HV_VLAN5_MAC_ADDR}
            vcu_vlan43_mac_addr=${VCU_HV_VLAN43_MAC_ADDR}
            vcu_vlan44_mac_addr=${VCU_HV_VLAN44_MAC_ADDR}
            vcu_vlan45_mac_addr=${VCU_HV_VLAN45_MAC_ADDR}
            vcu_vlan46_mac_addr=${VCU_HV_VLAN46_MAC_ADDR}

            vcu_vlan4_ipv4_addr=${VCU_HV_VLAN4_IPV4_ADDR}
            vcu_vlan5_ipv4_addr=${VCU_HV_VLAN5_IPV4_ADDR}
            vcu_vlan43_ipv4_addr=${VCU_HV_VLAN43_IPV4_ADDR}
            vcu_vlan44_ipv4_addr=${VCU_HV_VLAN44_IPV4_ADDR}
            vcu_vlan45_ipv4_addr=${VCU_HV_VLAN45_IPV4_ADDR}
            vcu_vlan46_ipv4_addr=${VCU_HV_VLAN46_IPV4_ADDR}
            ;;
        low)
            vcu_vlan4_mac_addr=${VCU_LV_VLAN4_MAC_ADDR}
            vcu_vlan5_mac_addr=${VCU_LV_VLAN5_MAC_ADDR}
            vcu_vlan43_mac_addr=${VCU_LV_VLAN43_MAC_ADDR}
            vcu_vlan44_mac_addr=${VCU_LV_VLAN44_MAC_ADDR}
            vcu_vlan45_mac_addr=${VCU_LV_VLAN45_MAC_ADDR}
            vcu_vlan46_mac_addr=${VCU_LV_VLAN46_MAC_ADDR}

            vcu_vlan4_ipv4_addr=${VCU_LV_VLAN4_IPV4_ADDR}
            vcu_vlan5_ipv4_addr=${VCU_LV_VLAN5_IPV4_ADDR}
            vcu_vlan43_ipv4_addr=${VCU_LV_VLAN43_IPV4_ADDR}
            vcu_vlan44_ipv4_addr=${VCU_LV_VLAN44_IPV4_ADDR}
            vcu_vlan45_ipv4_addr=${VCU_LV_VLAN45_IPV4_ADDR}
            vcu_vlan46_ipv4_addr=${VCU_LV_VLAN46_IPV4_ADDR}
            ;;
        *)
            echo "VCU HW variant is not supported: ${VCU_VARIANT}"
            exit 1
            ;;
    esac

    # Clean all neigh entries
    flush_all_neigh_entries

    echo "Creating VCU vlans..."
    set_vlan ${VCU_IFACE} 4  ${vcu_vlan4_ipv4_addr}  ${vcu_vlan4_mac_addr}  ${TCU_VLAN4_IPV4_ADDR}  ${TCU_MAC_ADDR}
    set_vlan ${VCU_IFACE} 5  ${vcu_vlan5_ipv4_addr}  ${vcu_vlan5_mac_addr}  ${TCU_VLAN5_IPV4_ADDR}  ${TCU_MAC_ADDR}
    set_vlan ${VCU_IFACE} 43 ${vcu_vlan43_ipv4_addr} ${vcu_vlan43_mac_addr} ${TCU_VLAN43_IPV4_ADDR} ${TCU_MAC_ADDR}
    set_vlan ${VCU_IFACE} 44 ${vcu_vlan44_ipv4_addr} ${vcu_vlan44_mac_addr} ${TCU_VLAN44_IPV4_ADDR} ${TCU_MAC_ADDR}
    set_vlan ${VCU_IFACE} 45 ${vcu_vlan45_ipv4_addr} ${vcu_vlan45_mac_addr} ${TCU_VLAN45_IPV4_ADDR} ${TCU_MAC_ADDR}
    set_vlan ${VCU_IFACE} 46 ${vcu_vlan46_ipv4_addr} ${vcu_vlan46_mac_addr} ${TCU_VLAN46_IPV4_ADDR} ${TCU_MAC_ADDR}
}

set_default_gw(){

    local iface=$1
    local ipv4_gw_addr=$2    
    local ipv6_gw_addr=$3

    if [[ $IPV6 -eq 1 ]]; then
        # Set default gw for IPv6
        ip -6 route del default 2> /dev/null || true
        ip -6 route add default via ${ipv6_gw_addr} dev ${iface} metric 1
        echo -e "Set IPv6 default gateway to: ${iface}: ${ipv6_gw_addr}"
    fi

    if [[ $NO4 -eq 0 ]]; then
        # Set default gw for IPv4
        ip -4 route del default 2> /dev/null || true
        ip -4 route add default via ${ipv4_gw_addr} dev ${iface} metric 1
        echo -e "Set IPv4 default gateway to: ${iface}: ${ipv4_gw_addr}"
    fi
}

set_dns_server(){

    local ipv4_dns_addr=$1
    local ipv6_dns_addr=$2
    
    # Set dns nameserver for IPv4
    echo "#Configuration created by ${PROGNAME}" > /etc/resolv.conf
    
    if [[ $IPV6 -eq 1 ]]; then
        echo "nameserver ${ipv6_dns_addr}" >> /etc/resolv.conf
        echo -e "Default IPv6 DNS server set to: ${ipv6_dns_addr}"
    fi

    if [[ $NO4 -eq 0 ]]; then
        echo "nameserver ${ipv4_dns_addr}" >> /etc/resolv.conf
        echo -e "Default IPv4 DNS server set to: ${ipv4_dns_addr}"
    fi
}

configure_vcu_default_gw_and_dns_server(){

    local ipv4_gw_addr
    local ipv4_dns_addr
    local ipv6_gw_addr
    local ipv6_dns_addr

    if [[ "$GATEWAY" =~ "4[3-6]" ]]; then
    
        usage
        exit -1    
    else

        case "$GATEWAY" in

        43)
            ipv4_gw_addr=${TCU_VLAN43_IPV4_ADDR}
            ipv4_dns_addr=${TCU_VLAN43_IPV4_ADDR}
            ipv6_gw_addr=${TCU_LINK_IPV6_ADDR}
            ipv6_dns_addr=${TCU_VLAN43_IPV6_ADDR}
            ;;
        44)
            ipv4_gw_addr=${TCU_VLAN44_IPV4_ADDR}
            ipv4_dns_addr=${TCU_VLAN44_IPV4_ADDR}
            ipv6_gw_addr=${TCU_LINK_IPV6_ADDR}
            ipv6_dns_addr=${TCU_VLAN44_IPV6_ADDR}
            ;;
        45)
            ipv4_gw_addr=${TCU_VLAN45_IPV4_ADDR}
            ipv4_dns_addr=${TCU_VLAN45_IPV4_ADDR}
            ipv6_gw_addr=${TCU_LINK_IPV6_ADDR}
            ipv6_dns_addr=${TCU_VLAN45_IPV6_ADDR}
            ;;
        46)
            ipv4_gw_addr=${TCU_VLAN46_IPV4_ADDR}
            ipv4_dns_addr=${TCU_VLAN46_IPV4_ADDR}
            ipv6_gw_addr=${TCU_LINK_IPV6_ADDR}
            ipv6_dns_addr=${TCU_VLAN46_IPV6_ADDR}
            ;;
        *)
            exit 1
            ;;
        esac
        
        set_default_gw ${VCU_IFACE}.${GATEWAY} ${ipv4_gw_addr} ${ipv6_gw_addr}
        set_dns_server ${ipv4_dns_addr} ${ipv6_dns_addr}
    fi
}

configure_wifi_hotspot() {

    bash -c "./linux-router/lnxrouter --ap ${WIFI_IFACE} ${SSID} -p ${PASSPHRASE} -o ${VCU_IFACE}.${BACKHAUL_IF} --dns 172.16.${BACKHAUL_IF}.102"
}

#############################  START  ################################

# if empty option, show usage and exit
check_empty_option "$@"

# TODO: are some global variables are still defined in those following code?
define_global_variables

# TODO: detect user option conflict
parse_user_options "$@"

# Check for VCU_IFACE matches any physical interface
ifconfig $VCU_IFACE  > /dev/null || exit -1

# Check options conflict
check_options_conflict

# Stop DHCPd or NetworkManager services to avoid having DHCP enabled
systemctl stop dhcpcd  || systemctl stop NetworkManager || exit -1

# Start creating vlans for $VCU_IFACE
create_vcu_vlans

# Configure default gw and dns resolver
configure_vcu_default_gw_and_dns_server

# Configure Wifi Hotspot
#configure_wifi_hotspot

exit 0
