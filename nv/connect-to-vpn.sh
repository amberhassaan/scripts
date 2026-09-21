#!/bin/bash 

# First command
eval $(openconnect --useragent="AnyConnect-compatible OpenConnect VPN Agent" --external-browser $(which google-chrome-stable) --authenticate ngvpn02.vpn.nvidia.com/SAML-EXT)
# Second command
[ -n ["$COOKIE"] ] && echo -n "$COOKIE" | sudo openconnect --cookie-on-stdin $CONNECT_URL --servercert $FINGERPRINT --resolve $RESOLVE
