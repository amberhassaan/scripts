#!/bin/bash 

SERVER="ngvpn51" # NJ
# SERVER="ngvpn05" # MA
# SERVER="ngvpn08" # Toronto

# get sudo cached first up
sudo ls /bin > /dev/null

# First command
eval $(openconnect --useragent="AnyConnect-compatible OpenConnect VPN Agent" --external-browser $(which google-chrome-stable) --authenticate $SERVER.vpn.nvidia.com/SAML-EXT)
# Second command
if [ -n "$COOKIE" ] ; then 
  echo -n "$COOKIE" | sudo openconnect --cookie-on-stdin $CONNECT_URL --servercert $FINGERPRINT --resolve $RESOLVE
fi;
