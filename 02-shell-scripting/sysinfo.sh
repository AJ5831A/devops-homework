#!/bin/bash

read -p "Enter your name: " USERNAME_INPUT
read -p "Enter a directory name to create: " DIR_NAME

CURRENT_DATE=$(date)
HOSTNAME=$(hostname)
CURRENT_USER=$(whoami)
DISK_USAGE=$(df -h .)

echo "=================================="
echo "        SYSTEM INFORMATION"
echo "=================================="
echo "Hello, $USERNAME_INPUT!"
echo "Date       : $CURRENT_DATE"
echo "Hostname   : $HOSTNAME"
echo "Username   : $CURRENT_USER"
echo ""
echo "Disk Usage :"
echo "$DISK_USAGE"
echo "=================================="

mkdir -p "$DIR_NAME"
echo "Directory '$DIR_NAME' created."

OUTPUT_FILE="$DIR_NAME/process_list.txt"
touch "$OUTPUT_FILE"
echo "File '$OUTPUT_FILE' created."

ps aux > "$OUTPUT_FILE"
echo "Running processes saved to $OUTPUT_FILE"
