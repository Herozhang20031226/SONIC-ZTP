Purpose: 
Capture the traffic from the test switch, when it is undergoing ZTP, and see what message is sent and what packets it is asking for. 

MacBook USB Ethernet adapter:
- Interface: en5
- IP address: 192.168.77.1/24 (manually assigned)
- MAC address: 00:e0:4c:68:03:e0

Test switch:
- Operating system: SONiC
- Management interface connected directly to MacBook
- DHCP-assigned address: 192.168.77.143
- Consoled in the MacBook

1. Connect the laptop to the Switch using ethernet conenction 
terminal: networksetup -listallhardwareports

2. Configure Static IP address for the Ethernet Adapter:
System Settings --> Network --> USB Ethernet adapter --> Details --> TCP/IP



3. Install python, dnsmasq, tftp-now
we need python as the HTTP server, and dnsmasq as both the TFTP and DHCP server. 
terminal: brew install dnsmasq python tftp-now


ztp-lab/
├── dnsmasq.conf
├── files/
│   └── ztp.cfg
├── captures/
│   └── ztp-20260721-123414.pcap




cat > /Users/Shared/ztp-lab/dnsmasq.conf <<EOF
# by setting the port to 0 it will not enable DNS, but will keep DHCP and TFTP on
port=0 

# ${IFACE} is replaced by the MacBook Ethernet Port, en5 in this case
interface=${IFACE}

# This tells dnsmasq to bind specifically to the configured interface instead of broadly listening and then filtering traffic.
bind-interfaces

dhcp-authoritative

log-dhcp
log-facility=-

dhcp-leasefile=/Users/Shared/ztp-lab/dnsmasq.leases

dhcp-range=192.168.77.100,192.168.77.150,255.255.255.0,1h

# no default gateway and dns-server
dhcp-option=option:router
dhcp-option=option:dns-server

# option 66 tells the switch where is the TFTP server
dhcp-option-force=66,"192.168.77.1"
# option 66 tells the switch which file to get
dhcp-option-force=67,"ztp.cfg"

enable-tftp
tftp-root=/Users/Shared/ztp-lab/files
EOF

4. start DHCP and TFTP
Terminal 1:
sudo "$(brew --prefix)/sbin/dnsmasq" \
  --no-daemon \
  --conf-file=/Users/Shared/ztp-lab/dnsmasq.conf

5. start HTTP
Terminal 2:
python3 -m http.server 8000 \
  --bind 192.168.77.1 \
  --directory /Users/Shared/ztp-lab/files

6. Capture packets:
Terminal 3:
export IFACE=en7

CAP="/Users/Shared/ztp-lab/captures/ztp-$(date +%Y%m%d-%H%M%S).pcap"

echo "Saving capture to: $CAP"

sudo tcpdump \
  -ni "$IFACE" \
  -s 0 \
  -w "$CAP"

7. Start the Switch in ZTP mode:
admin@sonic:~$ show ztp status
ZTP Admin Mode : False
ZTP Service    : Inactive
ZTP Status     : Not Started

ZTP Service is not running


admin@sonic:~$ sudo config ztp enable

Running command: ztp enable
admin@sonic:~$ 
admin@sonic:~$ sudo config ztp run
ZTP will be restarted. You may lose switch data and connectivity, continue? [y/N]: y
Running command: ztp run -y


Results:
