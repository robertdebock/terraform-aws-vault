#!/bin/bash -x

# set -o errexit
# set -o nounset
# set -o xtrace

# Remove old meterial
files="vault_ca.crt vault_ca.key vault_ca.srl vault.crt vault.csr vault.key"
for file in "${files}" ; do
  rm "${file}"
done

# Create CA
CA_CONFIG="
[ req ]
distinguished_name = dn
[ dn ]
[ ext ]
basicConstraints   = critical, CA:true, pathlen:1
keyUsage           = critical, digitalSignature, cRLSign, keyCertSign
"

# Create the CA key and certificate.
openssl req -config <(echo "$CA_CONFIG") -new -newkey rsa:2048 -nodes -subj "/CN=Snake Root CA" -x509 -extensions ext -keyout vault_ca.key -out vault_ca.crt

# Create new private key and CSR
openssl req -config request.cfg -new -newkey rsa:2048 -nodes -keyout vault.key -extensions ext -out vault.csr

# Sign the CSR.
openssl x509 -extfile request.cfg -extensions ext -req -in vault.csr -CA vault_ca.crt -CAkey vault_ca.key -CAcreateserial -out vault.crt -days 365

# Concatenate CA and server certificate
cat vault_ca.crt >> vault.crt
