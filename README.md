# Whale, Hello There!

## Provision the Infrastructure

### Set up your AWS client

First, ensure that you've configured your AWS CLI accordingly. Setting
that up is outside the scope of this guide so please go ahead and read
up at https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html


### Install Terraform

Grab the latest Terraform CLI [here](https://www.terraform.io/downloads.html)


### Install kubectl

Grab it via [this guide](https://kubernetes.io/docs/tasks/tools/#kubectl)


### Install eksctl

Grab it via [this guide](https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html)


### Install Helm

Grab it via [this guide](https://helm.sh/docs/intro/install/)


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

chmod 0600 ~/.kube/config
```


### Sanity Check: Double-check that Pods Can Reach the DB

```
kubectl run -i --tty --rm debug --image=busybox --restart=Never -- sh
If you don't see a command prompt, try pressing enter.
/ # telnet <HOSTNAME-PORTION-OF-db_endpoint-OUTPUT> <PORT-PORTION-OF-db_endpoint-OUTPUT>
Connected to <HOSTNAME>
<Press Ctrl-] then Enter then e>
/ # exit
```


### Log in to the UI and API Container Registries

While still in the terraform subdir:

```
aws ecr get-login-password --region $(terraform output -raw region) | \
  docker login --username AWS --password-stdin $(terraform output -raw registry_ui)

aws ecr get-login-password --region $(terraform output -raw region) | \
  docker login --username AWS --password-stdin $(terraform output -raw registry_api)
```


### Deploy Prometheus

For this section, we will follow [this AWS guide](https://docs.aws.amazon.com/eks/latest/userguide/prometheus.html):

```
kubectl create namespace prometheus

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

helm upgrade -i prometheus prometheus-community/prometheus \
    --namespace prometheus \
    --set alertmanager.persistentVolume.storageClass="gp2",server.persistentVolume.storageClass="gp2"
```

Watch for the status of each prometheus pod via:

```
watch -d kubectl get pods -n prometheus
```

Once all of them are up, temporarily set up port forwarding to access the
Prometheus UI:

```
kubectl --namespace=prometheus port-forward deploy/prometheus-server 9090
```

Browse to http://localhost:9090

When you're done, hit Ctrl-C to stop the port forwarding.


### Prepare the App's k8s Namespace

```
kubectl create ns whale
```


### Build and Deploy the UI

While in the project root:

```
cd ui

whale_registry=$(terraform -chdir=../terraform output -raw registry_ui)
image_version="$(date +%s)"

docker build -t whale-ui .

docker tag whale-ui $whale_registry:$image_version

docker push $whale_registry:$image_version

cat ui.yaml | \
  sed 's@REGISTRY_URL@'"${whale_registry}"'@' | \
  sed 's@IMAGE_VERSION@'"${image_version}"'@' | \
  kubectl apply -n whale -f -
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
