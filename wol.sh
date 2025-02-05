#!/bin/bash

# Wake-On-LAN Utility with Enhanced Features
# CHANGELOG
# 0.3 - 2025-02-04: - adicionado campo de descrição para o arquivo
# 0.2 - 2025-01-27: - opção de arquivo como input
#                   - registros de log
#                   - versão "interativa"
# 0.1 - 2024        - versão inicial (fonte: https://leesteve.tk/wol.sh)

# MIT License

# Log file for execution history
log_file="wol.log"

# Function to validate MAC address
validate_mac() {
    local mac=$1
    if [[ ! "$mac" =~ ^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$ ]]; then
        echo "Error: Invalid MAC address format. Example: AA:BB:CC:DD:EE:FF"
        exit 1
    fi
}

# Function to send magic packet
send_magic_packet() {
    local mac=$1
    local ip=${2:-"255.255.255.255"}
    local port=${3:-"9"}

    # Remove separators from MAC address input
    targetmac=$(echo "$mac" | sed 's/[ :-]//g')

    # Generate magic packet
    magicpacket=$(printf "f%.0s" {1..12}; printf "$targetmac%.0s" {1..16})
    magicpacket=$(echo "$magicpacket" | sed -e 's/../\\x&/g')

    # Log the action
    echo "$(date): Sending magic packet to MAC: $mac, IP: $ip, Port: $port" >> "$log_file"

    # Send magic packet using nc or socat
    printf "Sending magic packet to MAC: %s, IP: %s, Port: %s... " "$mac" "$ip" "$port"
    if command -v nc &> /dev/null; then
        if ! echo -e "$magicpacket" | nc -w1 -u "$ip" "$port"; then
            echo "Failed!"
            echo "$(date): Failed to send magic packet to MAC: $mac, IP: $ip, Port: $port" >> "$log_file"
            exit 1
        fi
    elif command -v socat &> /dev/null; then
        if ! echo -e "$magicpacket" | socat - UDP-DATAGRAM:"$ip:$port",broadcast; then
            echo "Failed!"
            echo "$(date): Failed to send magic packet to MAC: $mac, IP: $ip, Port: $port" >> "$log_file"
            exit 1
        fi
    else
        echo "Error: Neither 'nc' nor 'socat' is installed."
        exit 1
    fi
    echo "Done!"
    echo "$(date): Successfully sent magic packet to MAC: $mac, IP: $ip, Port: $port" >> "$log_file"
}

# Function to display help
display_help() {
    printf "Wake-On-LAN Utility
Usage:  WoL.sh [MAC] [IP] [Port]
   OR:  WoL.sh --file|-f <input_file>
   OR:  WoL.sh --interactive|-i
   OR:  WoL.sh --help|-h
Examples:
   ./WoL.sh AA:BB:CC:DD:EE:FF
   ./WoL.sh AA:BB:CC:DD:EE:FF 192.168.1.255 9
   ./WoL.sh --file input.txt
   ./WoL.sh --interactive
Input File Format:
   Each line should contain: MAC|IP|Port|Description
   Example: AA:BB:CC:DD:EE:FF|192.168.1.2|9|Desktop Office
   IP, Port, and Description are optional. If omitted, defaults will be used.
Interactive Mode:
   If no arguments are provided or '--interactive' is used, the script will prompt for MAC, IP, and Port.
Help:
   Use '--help' or '-h' to display this message.
"
    exit 0
}

# Main logic
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    display_help
fi

if [[ "$1" == "--interactive" || "$1" == "-i" || $# -eq 0 ]]; then
    # Interactive mode
    read -p "Enter MAC Address (required): " mac
    validate_mac "$mac"
    read -p "Enter IP Address (default: 255.255.255.255): " ip
    read -p "Enter Port (default: 9): " port
    ip=${ip:-"255.255.255.255"}
    port=${port:-"9"}
    send_magic_packet "$mac" "$ip" "$port"
    exit 0
fi

if [[ "$1" == "--file" || "$1" == "-f" ]]; then
    input_file="$2"
    if [ ! -f "$input_file" ]; then
        echo "Error: File '$input_file' not found."
        exit 1
    fi

    mapfile -t entries < "$input_file"
    if [ ${#entries[@]} -eq 0 ]; then
        echo "Error: The file is empty."
        exit 1
    fi

    echo "Available entries:"
    for i in "${!entries[@]}"; do
        IFS='|' read -r mac ip port description <<< "${entries[i]}"
        description=${description:-"(No description)"}
        echo "$((i + 1)): MAC: $mac, IP: ${ip:-255.255.255.255}, Port: ${port:-9}, Description: $description"
    done

    read -p "Select an entry number to send the magic packet: " choice

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#entries[@]} ]; then
        echo "Error: Invalid choice."
        exit 1
    fi

    IFS='|' read -r mac ip port description <<< "${entries[$((choice - 1))]}"
    validate_mac "$mac"
    ip=${ip:-"255.255.255.255"}
    port=${port:-"9"}
    send_magic_packet "$mac" "$ip" "$port"
else
    mac=$1
    ip=${2:-"255.255.255.255"}
    port=${3:-"9"}
    validate_mac "$mac"
    send_magic_packet "$mac" "$ip" "$port"
fi
