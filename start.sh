#!/bin/sh

if [ -z "$CONFIG_FILE" ]; then
  echo "The CONFIG_FILE environment variable is not set."
  exit 1
fi

# Check if the configuration file exists
if [ ! -f "/openvpn/$CONFIG_FILE" ]; then
  echo "The configuration file /openvpn/$CONFIG_FILE does not exist."
  exit 1
fi

# Get the initial IP address
initial_ip=$(curl -s ipinfo.io/ip)
echo "Initial IP: $initial_ip"

if [ -n "$OVPN_USER" ] && [ -n "$OVPN_PASS" ]; then
  # Create the OpenVPN credentials file
  echo -e "$OVPN_USER\n$OVPN_PASS" > /etc/openvpn/credentials
  # Start OpenVPN in the background with the credentials
  openvpn --config "/openvpn/$CONFIG_FILE" --auth-user-pass /etc/openvpn/credentials --daemon --log /var/log/openvpn.log
else
  openvpn --config "/openvpn/$CONFIG_FILE" --daemon --log /var/log/openvpn.log
fi

# Wait until OpenVPN is fully connected
echo "Waiting for OpenVPN to connect..."
while : ; do
    current_ip=$(curl -s ipinfo.io/ip)
    if [ "$initial_ip" != "$current_ip" ]; then
        echo "VPN active. Current IP: $current_ip"
        break
    else
        echo "Waiting for IP to change..."
        sleep 1
    fi
done

# Get the VPN interface
vpn_interface=$(ip -o -4 route show to default | awk '{print $5}')
echo "VPN interface: $vpn_interface"

# Configure iptables to redirect traffic through the VPN
iptables -t nat -A POSTROUTING -o $vpn_interface -j MASQUERADE
iptables -A FORWARD -i eth0 -o $vpn_interface -j ACCEPT
iptables -A FORWARD -i $vpn_interface -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Start Squid in the foreground
squid -N -d 1
