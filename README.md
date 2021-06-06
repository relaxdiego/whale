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


### Create the DB Credentials Secret in AWS

Here's an example of how to create one:

```
whale_env_name=<TYPE-IN-THE-VALUE-OF-env_name-TF-VARIABLE-HERE>

whale_secret_file=~/.whale/secrets/db_creds-${whale_env_name}.json
mkdir -p ~/.whale/secrets
chmod 0700 ~/.whale/secrets
cat > $whale_secret_file <<EOF
{
    "db_user": "SU_$(uuidgen | tr -d '-')",
    "db_pass": "$(uuidgen)"
}
EOF
chmod 0600 $whale_secret_file

aws secretsmanager create-secret \
  --name "whale-db-creds-${whale_env_name}"\
  --description "Whale DB credentials for ${whale_env_name} environment" \
  --secret-string file://$whale_secret_file
```


### And We're Off!

While still in the terraform subdir:

```
terraform apply
```


### Connect to the Bastion for the first time

Use [ssh4realz](https://github.com/relaxdiego/ssh4realz) to ensure
you connect to the bastion securely. For a guide on how to use the
script, see [this video](https://youtu.be/TcmOd4whPeQ).

While still in the terraform subdir:

```
ssh4realz $(terraform output -raw bastion1_instance_id)
```


### Subsequent Bastion SSH Connections

With the bastion's host key already saved to your known_hosts file,
just SSH directly to its public ip.

While still in the terraform subdir:

```
ssh -A ubuntu@$(terraform output -raw bastion1_public_ip)
```


### Set-up Your kubectl Config File

While still in the terraform subdir:

```
aws eks --region=$(terraform output -raw region) \
  update-kubeconfig \
  --name $(terraform output -raw k8s_cluster_name)

kubectl config use-context $(terraform output -raw k8s_cluster_arn)
```


### Clean Up That Blubber!

While still in the terraform subdir:

```
whale_env_name=<TYPE-IN-THE-VALUE-OF-env_name-TF-VARIABLE-HERE>

terraform destroy
aws secretsmanager delete-secret \
  --force-delete-without-recovery \
  --secret-id "whale-db-creds-${whale_env_name}"
```
