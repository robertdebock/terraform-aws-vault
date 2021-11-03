#!/usr/bin/env bash
#
# Creates a set of certificates for use with HashiCorp Vault
# https://learn.hashicorp.com/vault/operations/ops-deployment-guide

# set -o errexit
# set -o nounset
# set -o xtrace

TLS_PATH="./tls"

rm $TLS_PATH/*
test -d $TLS_PATH || mkdir -p $TLS_PATH

# Create CA
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
 -subj "/CN=Snake Root CA" -x509 -extensions ext -keyout $TLS_PATH/vault_ca.pem -out $TLS_PATH/vault_ca.crt

# # Create new private key and CSR
# openssl req -config request.cfg -new -newkey rsa:2048 -nodes \
#  -keyout $TLS_PATH/vault.pem -extensions ext -out $TLS_PATH/vault.csr
#
# # Sign the CSR
# openssl x509 -extfile request.cfg -extensions ext -req -in $TLS_PATH/vault.csr -CA $TLS_PATH/vault_ca.crt -CAkey $TLS_PATH/vault_ca.pem -CAcreateserial -out $TLS_PATH/vault.crt -days 365
#
# # Concatenate CA and server certificate
# cat $TLS_PATH/vault_ca.crt >> $TLS_PATH/vault.crt
