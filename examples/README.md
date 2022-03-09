# Examples

There are examples here to try, optionally to test in CI.

## Manual

To try an example manually:

```shell
cd ${EXAMPLE}
test -f id_rsa.pub || ssh-keygen -f id_rsa
./vault-tls.sh
terraform init
terraform apply
terraform destroy
```

Some scenarios have extra resources. Please read the `README.md` for the scenario to learn how to test those scenarios.

## Automatic (CI)

Simply add your scenario on `.github/workflows/terraform.yml` under: `jobs.terraform.strategy.matrix.config`.

Some scenarios are difficult to test in CI, because extra resources have to be created. For example:
- `mysubnet` required resources described in `examples/mysubnet/network`.
