FROM alpine:latest

# Install OpenVPN and other necessary utilities
RUN apk add --no-cache openvpn iproute2 squid curl iptables

# Create the necessary directories for OpenVPN
RUN mkdir -p /etc/squid /etc/openvpn /var/log/squid

# Copy configuration files (if you have them)
COPY squid.conf /etc/squid/squid.conf

# COPY nginx.conf /etc/nginx/nginx.conf

# Startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Default command to run OpenVPN
#CMD ["openvpn", "--config", "/openvpn/config.ovpn"]
CMD ["/start.sh"]
