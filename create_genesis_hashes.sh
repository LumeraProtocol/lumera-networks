#!/bin/bash

# create_genesis_hashes.sh
# Usage: ./create_genesis_hashes.sh [mainnet|testnet]

if [ $# -ne 1 ]; then
    echo "Usage: $0 [mainnet|testnet]"
    exit 1
fi

if [ "$1" != "mainnet" ] && [ "$1" != "testnet" ]; then
    echo "Error: Parameter must be either 'mainnet' or 'testnet'"
    exit 1
fi

NETWORK=$1
JSON_PATH="${NETWORK}/genesis.json"
ASC_PATH="${NETWORK}/genesis.asc"

if [ ! -f "$JSON_PATH" ]; then
    echo "Error: genesis.json not found at ${JSON_PATH}"
    exit 1
fi

# Create temporary file for normalized JSON
TMP_JSON=$(mktemp)
jq -S '.' "$JSON_PATH" > "$TMP_JSON"

# Generate hashes
SHA256=$(sha256sum "$TMP_JSON" | cut -d' ' -f1)
SHA512=$(sha512sum "$TMP_JSON" | cut -d' ' -f1)
SHAKE128=$(openssl dgst -shake128 "$TMP_JSON" | cut -d' ' -f2)
SHAKE256=$(openssl dgst -shake256 "$TMP_JSON" | cut -d' ' -f2)

# Create genesis.asc
cat > "$ASC_PATH" << EOF
SHA256=${SHA256}
SHA512=${SHA512}
SHAKE128=${SHAKE128}
SHAKE256=${SHAKE256}
EOF

rm "$TMP_JSON"

echo "Hash file created at ${ASC_PATH}"

