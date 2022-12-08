# Cloudwatch alarms

The original python scripts can be found in the folder `src`.
When these scripts are modified, the deployment package for the lambda function needs to be updated. 

You can update the package with `zip -j amazon-cloudwatch-auto-alarms.zip src/*` (modify paths where applicable). The next time `terraform apply` is executed after updating the package, Terraform will update the lambda function in AWS.
