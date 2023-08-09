# cloud9
```
cat cloud9-ubuntu-2204-ros2-humble-dcv.sh | sudo -E bash -
```

# mangdang

```
sudo cp 50-cloud.init.yaml /etc/netplan/50-cloud-init.yaml 
sudo apt install dnsmasq
sudo nano /etc/dnsmasq.d/usb
```
add the following 
```
interface=usb0
dhcp-range=10.55.0.2,10.55.0.6,255.255.255.248,1h
dhcp-option=3
leasefile-ro
port=0
```
Now uncomment the last line of /etc/default/dnsmasq:

```
# If the resolvconf package is installed, dnsmasq will tell resolvconf
# to use dnsmasq under 127.0.0.1 as the system's default resolver.
# Uncommenting this line inhibits this behaviour.
DNSMASQ_EXCEPT="lo"
```
