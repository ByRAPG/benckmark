for port in 8081 8082 8083 8084 8085; do
  echo "=== Probando puerto $port ==="
  curl -s -o /dev/null -w "HTTP %{http_code} - Tiempo: %{time_total}s\n" \
    -X POST "http://localhost:${port}/api/orders" \
    -H "Content-Type: application/json" \
    -d '{"customerId":"C123","items":[{"productId":"P1","quantity":2,"price":10.5},{"productId":"P2","quantity":1,"price":5.0}]}'
done