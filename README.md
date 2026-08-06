# SONiC ZTP Lab
This repository documents a Zero Touch Provisioning test for a SONiC switch using a Laptop. 

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
1. Connect the laptop to the switches management port using ethernet.
2. Console into the switch.
On the laptop go to settings, and then network.
<p align="center">
  <img src="images/1.png" alt="macOS Network settings" width="600">
</p>
Click on this and statically configure the IP address to 192.168.77.1, subnet mask to 255.255.255.0
<p align="center">
  <img src="images/2.png" alt="macOS Network settings" width="600">
</p>

To check which port on the laptop is connected to the switch. 
```bash
networksetup -listallhardwareports
```
In this case, it is port 5. 
```
Hardware Port: USB 10/100/1000 LAN
Device: en5
Ethernet Address: 00:e0:4c:68:03:e0
```

## Testing 
We need 3 terminals: 
In the first terminal, we will start the HTTP server. 
```
ROOT=/Users/Shared/ztp-lab
SERVER_IP=192.168.77.1

python3 -m http.server 8000 \
  --bind "$SERVER_IP" \
  --directory "$ROOT"
```

In the second terminal, we will start the DHCP server. 
```
ROOT=/Users/Shared/ztp-lab
DNSMASQ="$(brew --prefix)/sbin/dnsmasq"

sudo "$DNSMASQ" \
  --no-daemon \
  --conf-file="$ROOT/dnsmasq-sonic-ztp.conf"
```

In the third terminal, we will start ZTP on switch's console. 
Check the version of the firmware. 
```
show version
```

Check the status of ZTP
```
show ztp status
```

If it is disabled, we need to enable it and then run ZTP. 
```
sudo ztp enable
sudo ztp run -y
```

## Getting the conf_db from the switch
Once the switch gets the IP address from our laptop, we could extract the conf_db file from the switch. 
To test if the switch got the IP address, from the switch console ping the laptop. 
```
ping 192.168.77.1
```
To get the conf_db from the switch. 
```
scp admin@192.168.77.143:/home/admin/config_db-ztp.json \ /Users/Shared/ztp-lab/files/config_db.json
```

When we get the config file, we can navigate to hostname and change the hostname to something else. By doing so, we could test if the switch get this file successfully and if the configuration actually worked in this switch. We could simply check the hostname before and after the ZTP. 

## Results
If the DHCP worked, then in the terminal you should get something like:
```
dnsmasq: started, version 2.93 DNS disabled
dnsmasq-dhcp: DHCP, IP range 192.168.77.100 -- 192.168.77.150, lease time 1h
dnsmasq-dhcp: user class: SONiC-ZTP
dnsmasq-dhcp: client provides name: sonic
dnsmasq-dhcp: DHCPDISCOVER(en5) 192.168.77.143
dnsmasq-dhcp: DHCPOFFER(en5) 192.168.77.143
dnsmasq-dhcp: DHCPREQUEST(en5) 192.168.77.143
dnsmasq-dhcp: DHCPACK(en5) 192.168.77.143 sonic
dnsmasq-dhcp: option 67 bootfile-name http://192.168.77.1:8000/ztp/ztp.json
```
This means the switch successfully get the ip address from the laptop, as well as the bootfile-name and knows where to find the json file. 

In the HTTP server terminal, you should get:
```
Serving HTTP on 192.168.77.1 port 8000 (http://192.168.77.1:8000/) ...
192.168.77.143 - - [30/Jul/2026 14:42:05] "GET /ztp/ztp.json HTTP/1.1" 200 -
192.168.77.143 - - [30/Jul/2026 14:42:07] "GET /ztp/scripts/post_ztp.sh HTTP/1.1" 200 -
192.168.77.143 - - [30/Jul/2026 14:42:21] "GET /ztp/firmware/Enterprise_SONiC_OS_4.5.1_Lite.bin HTTP/1.1" 200 -
192.168.77.143 - - [30/Jul/2026 14:47:54] "GET /ztp/config/config_db.json HTTP/1.1" 200 -
```
This means the switch was able to get the json, script, firmware, and the config_db. 

If the switch successfully downloaded the firmware it should show:
```
sonic INFO sonic-ztp[3674377]: firmware: Version SONiC-OS-4.5.3-Lite successfully installed.
sonic INFO sonic-ztp[3674377]: firmware: Post image installation device reboot.
sonic INFO sonic-ztp[3674377]: firmware: Skipped switch reboot as requested.
sonic INFO sonic-ztp[3659221]: Processed Configuration section 001-firmware with result SUCCESS, exit code (0) at 2026-08-07 05:11:59 UTC.
```

This shows the switch is downloading the config_db and the provisioning-script.
```
sonic INFO sonic-ztp[15676]: configdb-json: Downloading config_db.json file from 'http://192.168.77.1:8000/ztp/config/config_db.json'.
ztp-test INFO sonic-ztp[4664]: Processed Configuration section 002-configdb-json with result SUCCESS, exit code (0) at 2026-08-07 05:20:39 UTC.
ztp-test INFO sonic-ztp[4664]: Processing configuration section 003-provisioning-script at 2026-08-07 05:20:39 UTC.
ztp-test INFO sonic-ztp[4664]: Processed Configuration section 003-provisioning-script with result SUCCESS, exit code (0) at 2026-08-07 05:21:07 UTC.
```

And finally, the switch confirmed everything is successful. 
```
sonic-ztp[4664]: Checking configuration section 001-firmware result: SUCCESS, ignore-result: False.
ztp-test INFO sonic-ztp[4664]: Checking configuration section 002-configdb-json result: SUCCESS, ignore-result: False.
ztp-test INFO sonic-ztp[4664]: Checking configuration section 003-provisioning-script result: SUCCESS, ignore-result: False.
sonic-ztp[4664]: ZTP successfully completed at 2026-08-07 05:21:07 UTC.
```

## Verification
To verify if the switch has downloaded the config_db.json, check if the hostname has updated.
```
admin@ztp-test:~$ show hostname
ztp-test
```

To verify if the switch has downloaded the firmware, check the version number.
```
admin@ztp-test:~$ show version
SONiC Software Version: SONiC-OS-4.5.3-Lite
```

To verify if the switch has downloaded the firmware, check the files in the switch's folder.
```
admin@ztp-test:~$ sudo ls -lah /host/ztp-test
total 16K
drwx------  4 root root 4.0K Aug  7 05:20 .
drwxr-xr-x 15 root root 4.0K Aug  7 05:13 ..
drw-------  2 root root 4.0K Jul 31 03:20 20260731_032004
drw-------  2 root root 4.0K Aug  7 05:21 20260807_052039
```
Every time we do a ztp test, it will create a folder. 

```
admin@ztp-test:~$ LATEST=$(sudo find /host/ztp-test \
  -mindepth 1 -maxdepth 1 -type d |
  sort |
  tail -n 1)

echo "$LATEST"
/host/ztp-test/20260807_052039
admin@ztp-test:~$ sudo find "$LATEST" -maxdepth 1 -type f -print
/host/ztp-test/20260807_052039/ztp_post_script_ran.txt
/host/ztp-test/20260807_052039/result_location.txt
/host/ztp-test/20260807_052039/ztp_sonic_installer_list.txt
/host/ztp-test/20260807_052039/ztp_show_version.txt
```
These are the files created by the provisioning script. 

We can check when we did the ztp test, and the version number. 
```
admin@ztp-test:~$ sudo cat "$LATEST/ztp_post_script_ran.txt"
ZTP post-provisioning script ran at Fri 07 Aug 2026 05:20:39 AM UTC
admin@ztp-test:~$ sudo cat "$LATEST/ztp_show_version.txt"

SONiC Software Version: SONiC-OS-4.5.3-Lite
```

