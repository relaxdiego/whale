# Whale, Hello There!

## Provision the Infrastructure

### Set up your AWS client

First, ensure that you've configured your AWS CLI accordingly. Setting
that up is outside the scope of this guide so please go ahead and read
up at https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html


### Install Terraform

Grab the latest Terraform CLI at https://www.terraform.io/downloads.html


### Initialize the Terraform Working Directory

```
cd terraform
terraform init
```


### Create Your Environment-Specific tfvars File

While still in the terraform subdir:

```
cp example.tfvars my-environment-specific.auto.tfvars
```

Then modify the file as you see fit.


### And We're Off!

While still in the terraform subdir:

```
terraform apply
```
