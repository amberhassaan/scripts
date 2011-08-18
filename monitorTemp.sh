#!/bin/bash

acpi -t

sep="-----------------------------------------------";

echo "$sep";

thermalzones=`ls /proc/acpi/thermal_zone/*/temperature 2> /dev/null`;

if [ -z "$thermalzones" ] ; then
  thermalzones=`ls /sys/bus/acpi/devices/LNXTHERM\:*/{path,thermal_zone/temp}`
fi;

for t in $thermalzones; do
  echo "$t";
  cat $t;
  echo "$sep";
done;


# echo -n "  CPU "
# cat /proc/acpi/thermal_zone/THM/temperature
# 
# nvidia-settings -q GPUCoreTemp  | head -n 2
# nvidia-settings -q GPUCurrentClockFreqs | head -n 2
