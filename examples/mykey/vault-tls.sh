#!/usr/bin/env bash

TLS_PATH="./tls"

rm $TLS_PATH/*
test -d $TLS_PATH || mkdir -p $TLS_PATH

# Create CA config.
CA_CONFIG="
[ req ]
distinguished_name = dn
[ dn ]
[ ext ]
basicConstraints   = critical, CA:true, pathlen:1
keyUsage           = critical, digitalSignature, cRLSign, keyCertSign
"

# Create CA key and certificate.
openssl req -config <(echo "$CA_CONFIG") -new -newkey rsa:2048 -nodes \
 -subj "/CN=Snake Root CA" -x509 -extensions ext -keyout $TLS_PATH/vault_ca.pem -out $TLS_PATH/vault_ca.crt -days 7300
