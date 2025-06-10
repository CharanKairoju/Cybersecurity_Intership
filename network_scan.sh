#!/bin/bash

# Network Vulnerability Assessment Script
# Author: Cybersecurity Intern
# Purpose: Automated network reconnaissance and vulnerability scanning

echo "========================================"
echo "    Network Vulnerability Scanner"
echo "========================================"

# Variables
TARGET_NETWORK="192.168.1.0/24"
OUTPUT_DIR="./scans"
DATE=$(date +%Y%m%d_%H%M%S)

# Create output directory
mkdir -p $OUTPUT_DIR

echo "[+] Starting network discovery..."

# Phase 1: Host Discovery
echo "[+] Discovering live hosts..."
nmap -sn $TARGET_NETWORK > $OUTPUT_DIR/host_discovery_$DATE.txt

# Extract live hosts
LIVE_HOSTS=$(nmap -sn $TARGET_NETWORK | grep -oP '(?<=Nmap scan report for )\d+\.\d+\.\d+\.\d+')

echo "[+] Live hosts found:"
echo "$LIVE_HOSTS"

# Phase 2: Port Scanning
echo "[+] Performing port scan on discovered hosts..."
for host in $LIVE_HOSTS; do
    echo "[+] Scanning $host..."
    
    # Quick scan for top 1000 ports
    nmap -sS -sV -O --top-ports 1000 $host -oN $OUTPUT_DIR/portscan_${host}_$DATE.txt
    
    # Vulnerability scan with scripts
    nmap --script vuln $host -oN $OUTPUT_DIR/vulnscan_${host}_$DATE.txt
    
    echo "[+] Completed scan for $host"
done

# Phase 3: Service Enumeration
echo "[+] Performing detailed service enumeration..."
for host in $LIVE_HOSTS; do
    # HTTP service enumeration
    nmap -p 80,443,8080 --script http-enum,http-headers,http-methods $host -oN $OUTPUT_DIR/http_enum_${host}_$DATE.txt
    
    # SMB enumeration
    nmap -p 445 --script smb-enum-domains,smb-enum-groups,smb-enum-processes,smb-enum-sessions,smb-enum-shares,smb-enum-users $host -oN $OUTPUT_DIR/smb_enum_${host}_$DATE.txt
    
    # SSH enumeration
    nmap -p 22 --script ssh-hostkey,ssh-auth-methods $host -oN $OUTPUT_DIR/ssh_enum_${host}_$DATE.txt
done

echo "[+] Scan completed! Results saved in $OUTPUT_DIR"
echo "[+] Summary of findings:"

# Generate summary
echo "========== SCAN SUMMARY ==========" > $OUTPUT_DIR/summary_$DATE.txt
echo "Scan Date: $(date)" >> $OUTPUT_DIR/summary_$DATE.txt
echo "Target Network: $TARGET_NETWORK" >> $OUTPUT_DIR/summary_$DATE.txt
echo "Live Hosts: $(echo "$LIVE_HOSTS" | wc -l)" >> $OUTPUT_DIR/summary_$DATE.txt
echo "" >> $OUTPUT_DIR/summary_$DATE.txt

# Count total open ports
TOTAL_PORTS=0
for host in $LIVE_HOSTS; do
    if [ -f "$OUTPUT_DIR/portscan_${host}_$DATE.txt" ]; then
        PORTS=$(grep "open" $OUTPUT_DIR/portscan_${host}_$DATE.txt | wc -l)
        echo "Host $host: $PORTS open ports" >> $OUTPUT_DIR/summary_$DATE.txt
        TOTAL_PORTS=$((TOTAL_PORTS + PORTS))
    fi
done

echo "Total Open Ports: $TOTAL_PORTS" >> $OUTPUT_DIR/summary_$DATE.txt
echo "" >> $OUTPUT_DIR/summary_$DATE.txt

echo "[+] Detailed summary saved to $OUTPUT_DIR/summary_$DATE.txt"
echo "[!] Remember to analyze results manually and correlate with Nessus/Wireshark data"
echo "[!] Next step: Run vulnerability assessment with Nessus"
