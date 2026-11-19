#!/bin/bash 

SERVER="ngvpn51" # NJ
# SERVER="ngvpn05" # MA
# SERVER="ngvpn08" # Toronto

IP="10.0.0.31"
PORT="2244"

# First command
eval $(openconnect --useragent="AnyConnect-compatible OpenConnect VPN Agent" --external-browser $(which google-chrome-stable) --authenticate $SERVER.vpn.nvidia.com/SAML-EXT)
# Second command
if [ -n "$COOKIE" ] ; then 
  CMD="echo -n \"$COOKIE\" | sudo openconnect -b --cookie-on-stdin $CONNECT_URL --servercert $FINGERPRINT --resolve $RESOLVE --pid-file /var/run/openconnect.pid"
  ssh -p $PORT $IP -f "nohup $($CMD)"
fi;

