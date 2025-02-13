#!/bin/bash

# Function to check if required commands are available
check_requirements() {
    local required_commands=("dig" "bc" "awk")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "Error: Required command '$cmd' is not installed."
            exit 1
        fi
    done
}

# Function to calculate statistics
calculate_stats() {
    local times=("$@")
    local sum=0
    local min=${times[0]}
    local max=${times[0]}
    
    # Calculate sum, min, and max
    for time in "${times[@]}"; do
        sum=$(echo "$sum + $time" | bc)
        if (( $(echo "$time < $min" | bc -l) )); then min=$time; fi
        if (( $(echo "$time > $max" | bc -l) )); then max=$time; fi
    done
    
    # Calculate mean
    local mean=$(echo "scale=2; $sum / ${#times[@]}" | bc)
    
    # Calculate standard deviation
    local variance=0
    for time in "${times[@]}"; do
        variance=$(echo "$variance + ($time - $mean)^2" | bc)
    done
    local stddev=$(echo "scale=2; sqrt($variance / ${#times[@]})" | bc)
    
    echo "$mean $min $max $stddev"
}

# Function to measure DNS resolution time
query_dns() {
    local domain="$1"
    local dns_server="$2"
    dig "@$dns_server" "$domain" +tries=1 +time=2 | grep "Query time:" | awk '{print $4}'
}

# Main function
main() {
    local domain="$1"
    local dns_server1="$2"
    local dns_server2="$3"
    local queries="${4:-100}"

    # Check arguments
    if [ -z "$domain" ] || [ -z "$dns_server1" ] || [ -z "$dns_server2" ]; then
        echo "Usage: $0 <domain> <dns_server1> <dns_server2> [number_of_queries]"
        echo "Example: $0 google.com 8.8.8.8 1.1.1.1 100"
        exit 1
    fi

    # Check requirements
    check_requirements

    echo "=== DNS Server Comparison ==="
    echo "Domain: $domain"
    echo "Number of queries: $queries"
    echo "DNS Server 1: $dns_server1"
    echo "DNS Server 2: $dns_server2"
    echo

    # Arrays to store query times
    declare -a times1=()
    declare -a times2=()

    # Progress bar function
    show_progress() {
        local current=$1
        local total=$2
        local width=50
        local percentage=$((current * 100 / total))
        local completed=$((width * current / total))
        printf "\rProgress: [%-${width}s] %d%%" "$(printf '#%.0s' $(seq 1 $completed))" "$percentage"
    }

    echo "Testing $dns_server1..."
    for ((i=1; i<=$queries; i++)); do
        show_progress $i $queries
        time=$(query_dns "$domain" "$dns_server1")
        times1+=($time)
        sleep 0.1  # Prevent flooding
    done
    echo

    echo "Testing $dns_server2..."
    for ((i=1; i<=$queries; i++)); do
        show_progress $i $queries
        time=$(query_dns "$domain" "$dns_server2")
        times2+=($time)
        sleep 0.1  # Prevent flooding
    done
    echo

    # Calculate statistics
    stats1=($(calculate_stats "${times1[@]}"))
    stats2=($(calculate_stats "${times2[@]}"))

    # Print results
    echo
    echo "=== Results ==="
    printf "\n%-20s %-15s %-15s\n" "" "$dns_server1" "$dns_server2"
    printf "%-20s %-15.2f %-15.2f\n" "Mean (ms)" "${stats1[0]}" "${stats2[0]}"
    printf "%-20s %-15.2f %-15.2f\n" "Min (ms)" "${stats1[1]}" "${stats2[1]}"
    printf "%-20s %-15.2f %-15.2f\n" "Max (ms)" "${stats1[2]}" "${stats2[2]}"
    printf "%-20s %-15.2f %-15.2f\n" "Std Dev (ms)" "${stats1[3]}" "${stats2[3]}"

    # Determine winner
    echo
    if (( $(echo "${stats1[0]} < ${stats2[0]}" | bc -l) )); then
        echo "$dns_server1 is faster by $(echo "${stats2[0]} - ${stats1[0]}" | bc)ms on average"
    else
        echo "$dns_server2 is faster by $(echo "${stats1[0]} - ${stats2[0]}" | bc)ms on average"
    fi
}

# Execute main function with all arguments
main "$@"
