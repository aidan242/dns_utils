# Test domains that are commonly accessed
domains=("google.com" "amazon.com" "netflix.com" "microsoft.com")

# DNS servers to test
dns_servers=(
    "74.40.74.40"  # Rogers
    "1.1.1.1"      # Cloudflare
    "8.8.8.8"      # Google
    "9.9.9.9"      # Quad9
)

echo "Testing DNS response times..."
echo "------------------------"

for dns in "${dns_servers[@]}"; do
    total_time=0
    for domain in "${domains[@]}"; do
        # Get query time using dig
        time=$(dig @$dns $domain +noall +stats | grep "Query time:" | awk '{print $4}')
        total_time=$((total_time + time))
        echo "$dns: $domain - ${time}ms"
    done
    avg_time=$((total_time / ${#domains[@]}))
    echo "Average for $dns: ${avg_time}ms"
    echo "------------------------"
done
