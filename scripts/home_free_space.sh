#!/bin/bash

free_space=$(df -h /home | awk 'NR==2 {print $4}')

echo "  $free_space"
