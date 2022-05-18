### Terraform commands
- `terraform init` -> init the project and installs the providers and the modules inside the [main.tf](./main.tf)
- `terraform providers` -> prints the providers used by the project
- `terraform validate` -> checks the syntax
- `terraform plan` -> generates an execution plan where you can review changes before it can take place
- `terraform apply` -> it will list the plan that terraform will apply if the prompt will be accepted
- `terraform show` -> inspects the plan and shows it in a human readable format
- `terraform destroy` -> destroy whatever the plan created