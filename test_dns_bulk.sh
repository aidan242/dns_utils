#!/bin/bash

# Configuration
ITERATIONS=100
domains=("google.com" "amazon.com" "netflix.com" "microsoft.com")
dns_servers=(
    "74.40.74.40"  # Rogers
    "1.1.1.1"      # Cloudflare
    "8.8.8.8"      # Google
    "9.9.9.9"      # Quad9
)

# Initialize arrays for storing results
declare -A total_times
declare -A query_counts
declare -A min_times
declare -A max_times

# Initialize arrays with default values
for dns in "${dns_servers[@]}"; do
    total_times[$dns]=0
    query_counts[$dns]=0
    min_times[$dns]=9999
    max_times[$dns]=0
done

echo "Starting DNS performance test..."
echo "Testing ${#dns_servers[@]} DNS servers"
echo "Running $ITERATIONS iterations for each domain"
echo "------------------------"

# Progress counter
total_queries=$((ITERATIONS * ${#domains[@]} * ${#dns_servers[@]}))
current_query=0

for ((i=1; i<=ITERATIONS; i++)); do
    for dns in "${dns_servers[@]}"; do
        for domain in "${domains[@]}"; do
            # Update progress
            current_query=$((current_query + 1))
            progress=$((current_query * 100 / total_queries))
            echo -ne "Progress: $progress%\r"
            
            # Get query time using dig
            time=$(dig @$dns $domain +noall +stats +timeout=2 2>/dev/null | grep "Query time:" | awk '{print $4}')
            
            # Check if dig command succeeded
            if [ ! -z "$time" ]; then
                total_times[$dns]=$((${total_times[$dns]} + time))
                query_counts[$dns]=$((${query_counts[$dns]} + 1))
                
                # Update min/max times
                if [ $time -lt ${min_times[$dns]} ]; then
                    min_times[$dns]=$time
                fi
                if [ $time -gt ${max_times[$dns]} ]; then
                    max_times[$dns]=$time
                fi
            fi
        done
    done
done

echo -e "\n\nResults:"
echo "------------------------"
printf "%-15s %-10s %-10s %-10s %-10s\n" "DNS Server" "Avg (ms)" "Min (ms)" "Max (ms)" "Queries"
echo "------------------------"

for dns in "${dns_servers[@]}"; do
    if [ ${query_counts[$dns]} -gt 0 ]; then
        avg=$((${total_times[$dns]} / ${query_counts[$dns]}))
        printf "%-15s %-10s %-10s %-10s %-10s\n" \
            "$dns" \
            "$avg" \
            "${min_times[$dns]}" \
            "${max_times[$dns]}" \
            "${query_counts[$dns]}"
    else
        printf "%-15s %-10s\n" "$dns" "Failed"
    fi
done

echo -e "\nTest completed!"
