# TLS

If you have your own TLS material, please place the files here:

- `vault.key`
- `vault.crt`
- `vault_ca.crt`

Generate the required file by going into this directory and running a script:

```shell
cd examples/default/tls
./create_tls_material.sh
```
