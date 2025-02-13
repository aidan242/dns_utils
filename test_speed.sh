#!/bin/bash

# Function to check if required commands are available
check_requirements() {
    local required_commands=("dig" "ping")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "Error: Required command '$cmd' is not installed."
            exit 1
        fi
    done
}

# Function to measure DNS resolution time
check_dns_time() {
    local url="$1"
    local dns_server="$2"
    
    if [ -n "$dns_server" ]; then
        echo "Testing DNS resolution for $url using DNS server $dns_server"
        dig "@$dns_server" "$url" | grep "Query time:" | awk '{print $4}'
    else
        echo "Testing DNS resolution for $url using default DNS"
        dig "$url" | grep "Query time:" | awk '{print $4}'
    fi
}

# Function to measure connection latency
check_latency() {
    local url="$1"
    echo "Testing connection latency to $url"
    ping -c 4 "$url" | tail -1 | awk '{print $4}' | cut -d '/' -f 2
}

# Main function
main() {
    local url1="$1"
    local url2="$2"
    local dns_server="$3"

    # Check if URLs are provided
    if [ -z "$url1" ] || [ -z "$url2" ]; then
        echo "Usage: $0 <url1> <url2> [dns_server]"
        echo "Example: $0 google.com cloudflare.com 8.8.8.8"
        exit 1
    fi

    # Check for required commands
    check_requirements

    echo "=== DNS Resolution Speed Test ==="
    echo

    # Test first URL
    echo "Testing $url1:"
    dns_time1=$(check_dns_time "$url1" "$dns_server")
    latency1=$(check_latency "$url1")
    echo "DNS Resolution time: ${dns_time1}ms"
    echo "Average latency: ${latency1}ms"
    echo

    # Test second URL
    echo "Testing $url2:"
    dns_time2=$(check_dns_time "$url2" "$dns_server")
    latency2=$(check_latency "$url2")
    echo "DNS Resolution time: ${dns_time2}ms"
    echo "Average latency: ${latency2}ms"
    echo

    # Compare results
    echo "=== Comparison ==="
    echo "DNS Resolution Times:"
    echo "$url1: ${dns_time1}ms"
    echo "$url2: ${dns_time2}ms"
    echo
    echo "Connection Latency:"
    echo "$url1: ${latency1}ms"
    echo "$url2: ${latency2}ms"
}

# Execute main function with all arguments
main "$@"
