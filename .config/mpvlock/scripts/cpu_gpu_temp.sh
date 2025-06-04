#!/bin/bash

cpu_temp=$(printf "%.0f" $(awk '{print $1/1000}' /sys/class/hwmon/hwmon4/temp1_input))
gpu_temp=$(printf "%.0f" $(awk '{print $1/1000}' /sys/class/hwmon/hwmon5/temp1_input))

echo "CPU/GPU °C: ${cpu_temp} / ${gpu_temp}"

