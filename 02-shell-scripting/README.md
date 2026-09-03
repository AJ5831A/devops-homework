# Shell Scripting — System Information Script

A bash script (`sysinfo.sh`) that reports system information and demonstrates
variables, user input, directory/file creation, and output redirection.

## What the script does

- Prints the current date
- Prints the hostname
- Prints the username
- Prints the disk usage
- Prints the running processes (saved to a file)
- Uses variables to store and reuse data
- Takes user input with `read -p`
- Creates a directory with `mkdir`
- Creates a file with `touch`
- Redirects `ps aux` output into that file with `>`

## Commands used

`mkdir`, `touch`, `echo`, `df`, `ps`, `read -p`, shell variables, `>` output redirection

## Script

```bash
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
```

## How to run

```bash
chmod +x sysinfo.sh
./sysinfo.sh
```

You'll be prompted for your name and a directory name; the script then prints
system info and writes the current process list to `<directory>/process_list.txt`.

## Sample output

Run on macOS (bash), with inputs `Aryan` and `process_output`:

```
Enter your name: Aryan
Enter a directory name to create: process_output
==================================
        SYSTEM INFORMATION
==================================
Hello, Aryan!
Date       : Thu Sep  3 11:10:06 IST 2026
Hostname   : Aryans-MacBook-Pro.local
Username   : aryanjakhar

Disk Usage :
Filesystem      Size    Used   Avail Capacity iused ifree %iused  Mounted on
/dev/disk3s1   460Gi    45Gi   394Gi    11%    852k  4.1G    0%   /System/Volumes/Data
==================================
Directory 'process_output' created.
File 'process_output/process_list.txt' created.
Running processes saved to process_output/process_list.txt
```

`process_output/process_list.txt` then contains the full `ps aux` listing, e.g.:

```
USER               PID  %CPU %MEM      VSZ    RSS   TT  STAT STARTED      TIME COMMAND
root              3547  15.8  0.1 435383456  35072   ??  Ss   Tue10AM   0:13.19 /System/Library/...
aryanjakhar       1773   9.5  0.2 435469824  39104   ??  S    Tue12AM 561:22.02 /System/Library/...
...
```

> Note: `mkdir`, `touch`, `df`, `ps` behave identically on Linux and macOS, so the
> same script runs unchanged on an Ubuntu box — only the `df -h` column
> formatting differs slightly.
