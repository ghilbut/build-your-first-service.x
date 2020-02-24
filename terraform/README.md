## Initialize

```bash

## Development environment

### initialize

$ terraform init

$ terraform workspace list
* default

$ terraform workspace new local
$ terraform workspace list
  default
* local

$ terraform workspace new developement
$ terraform workspace list
  default
  local
* development

### Local stage

$ terraform workspace select local
$ terraform plan -var-file=local.tfvars
$ terraform apply -var-file=local.tfvars

### Development stage

$ terraform workspace select developement
$ terraform plan -var-file=development.tfvars
$ terraform apply -var-file=development.tfvars

## Production environment

### Staging stage

### Production stage

```
