#!/bin/bash
# Generate RSA key pair for PowerSync JWT authentication

echo "Generating RSA key pair..."

# Generate private key
openssl genrsa -out keys/private.pem 2048

# Extract public key
openssl rsa -in keys/private.pem -pubout -out keys/public.pem

# Convert public key to single line format for env var
PUBLIC_KEY=$(cat keys/public.pem | tr -d '\n')

echo ""
echo "=== Keys generated in ./keys/ ==="
echo ""
echo "Add this to your .env file:"
echo "POWERSYNC_PUBLIC_KEY=\"$PUBLIC_KEY\""
echo ""
echo "Or add to docker-compose.dev.yml environment:"
echo "POWERSYNC_PUBLIC_KEY: |"
cat keys/public.pem | sed 's/^/      /'
