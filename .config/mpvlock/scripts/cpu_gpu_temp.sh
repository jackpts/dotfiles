#!/bin/bash

cpu_temp=$(awk '{print $1/1000}' /sys/class/hwmon/hwmon4/temp1_input | bc -l)
gpu_temp=$(awk '{print $1/1000}' /sys/class/hwmon/hwmon5/temp1_input | bc -l)

echo "CPU/GPU Temp: ${cpu_temp} / ${gpu_temp}"

