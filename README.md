# SONiC ZTP Lab
This repository documents a Zero Touch Provisioning test for a SONiC switch using a MacBook. 

## Goal
1. Obtain an IP address through DHCP
2. Download a ZTP configuration file
3. Download a SONiC configuration
4. Install a firmware image

## Repository layout

```
ztp-lab/
├── dnsmasq-sonic-ztp.conf    # Configures DHCP and provides the SONiC ZTP URL
├── files/                    
│   └── ztp/
│       ├── ztp.json          # Defines the SONiC ZTP provisioning actions
│       ├── config_db.json    # Contains the SONiC switch configuration
│       └── scripts/
│           └── post_ztp.sh   # Runs additional commands after provisioning
└── captures/                 # Stores packet captures from ZTP testing
```

## Installation
We need dnsmasq for the DHCP server, and python for the HTTP server. 

```bash
brew install dnsmasq
```

## Configuration
1. Connect the Mac to the switches management port using ethernet.
2. Console into the switch.
On the Mac go to settings, and then network.
<p align="center">
  <img src="images/1.png" alt="macOS Network settings" width="600">
</p>
Click on this and statically configure the IP address to 192.168.77.1, subnet mask to 255.255.255.0
<p align="center">
  <img src="images/2.png" alt="macOS Network settings" width="600">
</p>

To check which port on the Mac is connected to the switch. 
```bash
networksetup -listallhardwareports
```
In this case, it is port 5. 
```
Hardware Port: USB 10/100/1000 LAN
Device: en5
Ethernet Address: 00:e0:4c:68:03:e0
```












