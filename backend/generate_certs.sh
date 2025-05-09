#!/bin/bash

# Script to generate self-signed SSL certificates for development
# DO NOT use these certificates in production!

# Create certs directory if it doesn't exist
mkdir -p certs

# Generate a private key
openssl genrsa -out certs/key.pem 2048

# Generate a certificate signing request
openssl req -new -key certs/key.pem -out certs/csr.pem -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"

# Generate a self-signed certificate (valid for 365 days)
openssl x509 -req -days 365 -in certs/csr.pem -signkey certs/key.pem -out certs/cert.pem

# Remove the CSR as it's no longer needed
rm certs/csr.pem

echo "Self-signed certificates generated in the 'certs' directory."
echo "Update your .env file with:"
echo "CERT_FILE=$(pwd)/certs/cert.pem"
echo "KEY_FILE=$(pwd)/certs/key.pem"
echo ""
echo "NOTE: These are self-signed certificates for development only."
echo "For production, use certificates from a trusted CA like Let's Encrypt."