<#
.SYNOPSIS
    Wake-On-LAN Utility for PowerShell
.DESCRIPTION
    This script sends a magic packet to wake up a machine properly configured to listen to Wake-On-LAN/WLAN requests.
.PARAMETER MAC
    Mandatory. The MAC address of the target machine.
.PARAMETER IP
    Optional. The IP address to which the magic packet will be sent. Default: 255.255.255.255.
.PARAMETER Port
    Optional. The port to which the magic packet will be sent. Default: 9.
.PARAMETER File
    Optional. Path to an input file containing MAC, IP, Port, and Description.
.PARAMETER Interactive
    Optional. Enables interactive mode to prompt for MAC, IP, and Port.
.EXAMPLE
    .\wol.ps1 AA:BB:CC:DD:EE:FF
.EXAMPLE
    .\wol.ps1 AA:BB:CC:DD:EE:FF 192.168.1.255 9
.EXAMPLE
    .\wol.ps1 -File input.txt
.EXAMPLE
    .\wol.ps1 -Interactive
.NOTES
    Project homepage: https://leesteve.tk/wol.sh
    Version: 0.1 (Pre-release)
    License: MIT
#>

param (
    [Parameter(Mandatory = $false)]
    [string]$MAC,

    [Parameter(Mandatory = $false)]
    [string]$IP = "255.255.255.255",

    [Parameter(Mandatory = $false)]
    [int]$Port = 9,

    [Parameter(Mandatory = $false)]
    [string]$File,

    [Parameter(Mandatory = $false)]
    [switch]$Interactive
)

# Log file for execution history
$logFile = "wol.log"

# Function to validate MAC address
function Validate-MAC {
    param (
        [string]$mac
    )
    if ($mac -notmatch '^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$') {
        Write-Host "Error: Invalid MAC address format. Example: AA:BB:CC:DD:EE:FF" -ForegroundColor Red
        exit 1
    }
}

# Function to send magic packet
function Send-MagicPacket {
    param (
        [string]$mac,
        [string]$ip,
        [int]$port
    )
    # Remove separators from MAC address
    $targetMac = $mac -replace '[ :-]', ''

    # Generate magic packet (12 'f' followed by 16 repetitions of MAC)
    $magicPacket = ("f" * 12) + ($targetMac * 16)

    # Convert hex string to byte array
    $byteArray = @()
    for ($i = 0; $i -lt $magicPacket.Length; $i += 2) {
        $byteArray += [Convert]::ToByte($magicPacket.Substring($i, 2), 16)
    }

    # Create UDP client and send magic packet
    try {
        $udpClient = New-Object System.Net.Sockets.UdpClient
        $udpClient.Connect($ip, $port)
        $bytesSent = $udpClient.Send($byteArray, $byteArray.Length)
        Write-Host "Magic packet sent to MAC: $mac, IP: $ip, Port: $port" -ForegroundColor Green
        Add-Content -Path $logFile -Value "$(Get-Date): Successfully sent magic packet to MAC: $mac, IP: $ip, Port: $port"
    } catch {
        Write-Host "Failed to send magic packet." -ForegroundColor Red
        Add-Content -Path $logFile -Value "$(Get-Date): Failed to send magic packet to MAC: $mac, IP: $ip, Port: $port"
        exit 1
    } finally {
        $udpClient.Close()
    }
}

# Display help
function Show-Help {
    Write-Host @"
Wake-On-LAN Utility for PowerShell

Usage:
    .\wol.ps1 [MAC] [IP] [Port]
    .\wol.ps1 -File <input_file>
    .\wol.ps1 -Interactive

Examples:
    .\wol.ps1 AA:BB:CC:DD:EE:FF
    .\wol.ps1 AA:BB:CC:DD:EE:FF 192.168.1.255 9
    .\wol.ps1 -File input.txt
    .\wol.ps1 -Interactive

Input File Format:
    Each line should contain: MAC|IP|Port|Description
    Example: AA:BB:CC:DD:EE:FF|192.168.1.2|9|Desktop Office
    IP, Port, and Description are optional. If omitted, defaults will be used.
"@
    exit 0
}

# Main logic
if ($Interactive) {
    # Interactive mode
    $MAC = Read-Host "Enter MAC Address (required)"
    Validate-MAC $MAC
    $IP = Read-Host "Enter IP Address (default: 255.255.255.255)" | ForEach-Object { if ($_ -eq "") { "255.255.255.255" } else { $_ } }
    $Port = Read-Host "Enter Port (default: 9)" | ForEach-Object { if ($_ -eq "") { 9 } else { [int]$_ } }
    Send-MagicPacket -mac $MAC -ip $IP -port $Port
    exit 0
}

if ($File) {
    # File mode
    if (-Not (Test-Path $File)) {
        Write-Host "Error: File '$File' not found." -ForegroundColor Red
        exit 1
    }

    $entries = Get-Content $File
    if ($entries.Count -eq 0) {
        Write-Host "Error: The file is empty." -ForegroundColor Red
        exit 1
    }

    Write-Host "Available entries:"
    for ($i = 0; $i -lt $entries.Count; $i++) {
        $entry = $entries[$i] -split '\|'
        $mac = $entry[0]
        $ip = $entry[1] ? $entry[1] : "255.255.255.255"
        $port = $entry[2] ? $entry[2] : 9
        $description = $entry[3] ? $entry[3] : "(No description)"
        Write-Host "$($i + 1): MAC: $mac, IP: $ip, Port: $port, Description: $description"
    }

    $choice = Read-Host "Select an entry number to send the magic packet"
    if (-Not ($choice -match '^\d+$') -or $choice -lt 1 -or $choice -gt $entries.Count) {
        Write-Host "Error: Invalid choice." -ForegroundColor Red
        exit 1
    }

    $selectedEntry = $entries[$choice - 1] -split '\|'
    $MAC = $selectedEntry[0]
    $IP = $selectedEntry[1] ? $selectedEntry[1] : "255.255.255.255"
    $Port = $selectedEntry[2] ? [int]$selectedEntry[2] : 9
    Validate-MAC $MAC
    Send-MagicPacket -mac $MAC -ip $IP -port $Port
} elseif ($MAC) {
    # Direct mode
    Validate-MAC $MAC
    Send-MagicPacket -mac $MAC -ip $IP -port $Port
} else {
    # Show help if no arguments
    Show-Help
}
