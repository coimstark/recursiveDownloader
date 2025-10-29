#!/bin/bash
# Anthony/Rabiaza
# 2018-02-31
# Modified for macOS compatibility

# wget parameters:
# -T 60: timeout of 60 sec
# -nv: non verbose 
# -nc: skip downloads that would download to existing files
# --secure-protocol=TLSv1 --no-check-certificate: security related
wget_params="-T 60 -nv -nc --secure-protocol=TLSv1 --no-check-certificate"

function help() {
    echo "Please run this utility with the URL of the WSDL/XSD as argument"
    echo -e "\tFor instance:"
    echo -e "\t$0 http://192.168.0.96:8080/HelloWorld_WebServiceProject/wsdl/HelloWorld.wsdl"
    echo ""
    echo "Note: This script requires wget. Install via Homebrew if needed:"
    echo -e "\tbrew install wget"
}

function download() {
    local filename=${1##*/}
    if [ "$filename" == "" ]; then
        echo -e "\tError for $1"
        echo -ne "\t\t"
        return 1
    fi
    echo -e "\tDownloading $filename"
    echo -en "\t\twget -> "
    wget $wget_params "$1"
    echo ""
}

function getDependencies() {
    local file="$1"
    local base_path="$2"
    
    # Use sed instead of grep -P for macOS compatibility
    local nbOccurrences=$(grep -o 'schemaLocation' "$file" 2>/dev/null | wc -l | tr -d ' ')
    
    if [ "$nbOccurrences" -gt 0 ]; then
        # Extract schemaLocation values using sed (macOS compatible)
        local dependencies=$(sed -n 's/.*schemaLocation="\([^"]*\)".*/\1/p' "$file")
        
        echo "$dependencies" | while read -r dependency; do
            if [ -n "$dependency" ]; then
                download "$base_path/$dependency"
                getDependencies "$dependency" "$base_path"
            fi
        done
    else
        echo -e "\t\tNo more dependencies for $file"
    fi
}

# Check if wget is installed
if ! command -v wget &> /dev/null; then
    echo "Error: wget is not installed"
    echo "Please install it using Homebrew:"
    echo "  brew install wget"
    exit 1
fi

if [ $# -lt 1 ]; then
    help
    exit 1
fi

currentDir="$PWD"
echo "Recursive Downloader (macOS Compatible)"
echo "Command:    $0"
echo "Parameters: $*"
echo ""
echo "Creating output folder"
mkdir -p output
cd output || exit 1

filename=${1##*/}
serverPath=${1%/*}
echo "File to download $filename on $serverPath"
download "$1"
getDependencies "$filename" "$serverPath"
cd "$currentDir" || exit 1