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
terraform -chdir=terraform init
```


### Create Your Environment-Specific tfvars File

```
cp terraform/example.tfvars terraform.tfvars
```

Then modify the file as you see fit.


### Create the DB Credentials Secret in AWS


```
whale_aws_cli_profile=$(grep -E ' *profile *=' terraform/terraform.tfvars | sed -E 's/ *profile *= *"(.*)"/\1/g')
whale_aws_region=$(grep -E ' *region *=' terraform/terraform.tfvars | sed -E 's/ *region *= *"(.*)"/\1/g')
whale_env_name=$(grep -E ' *env_name *=' terraform/terraform.tfvars | sed -E 's/ *env_name *= *"(.*)"/\1/g')
whale_db_creds_secret_name=$(grep ' *db_creds_secret_name *=' terraform/terraform.tfvars | sed -E 's/ *db_creds_secret_name *= *"(.*)"/\1/g')
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
  --profile "$whale_aws_cli_profile" \
  --name "$whale_db_creds_secret_name" \
  --description "Whale DB credentials for ${whale_env_name} environment" \
  --secret-string file://$whale_secret_file
```


### Create a Route 53 Zone for Your Environment

First, get a hold of an FQDN that you own and define it in an env var:

```
whale_zone_fqdn=<TYPE-IN-YOUR-FQDN-HERE>
```

Let's also create a unique caller reference:

```
whale_route53_caller_reference=$(uuidgen | tr -d '-')
```

Then, create the zone:

```
whale_aws_cli_profile=$(grep -E ' *profile *=' terraform/terraform.tfvars | sed -E 's/ *profile *= *"(.*)"/\1/g')
whale_aws_region=$(grep -E ' *region *=' terraform/terraform.tfvars | sed -E 's/ *region *= *"(.*)"/\1/g')

aws route53 create-hosted-zone \
  --profile "$whale_aws_cli_profile" \
  --name "$whale_zone_fqdn" \
  --caller-reference "$whale_route53_caller_reference" > tmp/create-hosted-zone.out
```

List the nameservers for your zone:

```
cat tmp/create-hosted-zone.out | jq -r '.DelegationSet.NameServers[]'
```

Now modify your DNS servers to use the hosts listed above.


### And We're Off!


```
terraform -chdir=terraform apply
```

Proceed once the above is done.


### (Optional) Connect to the Bastion for the First Time

Use [ssh4realz](https://github.com/relaxdiego/ssh4realz) to ensure
you connect to the bastion securely. For a guide on how to (and why)
use the script, see [this video](https://youtu.be/TcmOd4whPeQ).

```
ssh4realz $(terraform -chdir=terraform output -raw bastion1_instance_id)
```


### Subsequent Bastion SSH Connections

With the bastion's host key already saved to your known_hosts file,
just SSH directly to its public ip.

```
ssh -A ubuntu@$(terraform -chdir=terraform output -raw bastion1_public_ip)
```


### Set-up Your kubectl Config File

Back in your local machine

```
aws eks --region=$(terraform -chdir=terraform output -raw region) \
  update-kubeconfig \
  --name $(terraform -chdir=terraform output -raw k8s_cluster_name)

kubectl config use-context $(terraform -chdir=terraform output -raw k8s_cluster_arn)

chmod 0600 ~/.kube/config
```

Check that you're able to connect to the kube-api-server:

```
kubectl get pods --all-namespaces
```


### Sanity Check: Double-check that Pods Can Reach the DB

```
# Print out the DB endpoint for reference
terraform -chdir=terraform output db_endpoint

kubectl run -i --tty --rm debug --image=busybox --restart=Never -- sh
```

Once in the prompt, run:

```
/ # telnet <HOSTNAME-PORTION-OF-db_endpoint-OUTPUT> <PORT-PORTION-OF-db_endpoint-OUTPUT>
```

It should output:

```
Connected to <HOSTNAME>
```

To exit:

```
<Press Ctrl-] then Enter then e>
/ # exit
```


### Log in to the UI and API Container Registries

```
aws ecr get-login-password --region $(terraform -chdir=terraform output -raw region) | \
  docker login --username AWS --password-stdin $(terraform -chdir=terraform output -raw registry_ui)

aws ecr get-login-password --region $(terraform -chdir=terraform output -raw region) | \
  docker login --username AWS --password-stdin $(terraform -chdir=terraform output -raw registry_api)
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


### Ensure Your Cluster Has an OpenID Connect Provider

OIDC will be used by some pods in the cluster to connect to the AWS API.
This section will be based off of [this guide](https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html)

First check if the cluster already has an OIDC provider:

```
aws eks describe-cluster \
    --region $(terraform -chdir=terraform output -raw region) \
    --name $(terraform -chdir=terraform output -raw k8s_cluster_name) \
    --query "cluster.identity.oidc.issuer" \
    --output text
```

It should return something like:

```
https://oidc.eks.us-west-2.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E
```

Now grep that sample ID from your list of OIDC providers:

```
aws iam list-open-id-connect-providers | grep <EXAMPLED539D4633E53DE1B716D3041E>
```

If the above command returned an ARN, you're done with this section. If
it did not return one, then run:

```
eksctl utils associate-iam-oidc-provider \
    --region $(terraform -chdir=terraform output -raw region) \
    --cluster $(terraform -chdir=terraform output -raw k8s_cluster_name) \
    --approve
```

Rerun the aws iam command above again (including the pipe to grep) to
double check.


### Install cert-manager

```
kubectl apply --validate=false -f cert-manager/cert-manager.yaml
```

Watch for the status of each pod via:

```
watch -d kubectl get pods -n cert-manager
```


### Install the Load Balancer Controller

We will base the following steps on [this guide](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.2/deploy/installation/)

```
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://aws-lb-controller/iam-policy.json | \
  tee tmp/iam-policy.out

whale_aws_account_id=$(terraform -chdir=terraform output -raw account_id)
whale_k8s_cluster_name=$(terraform -chdir=terraform output -raw k8s_cluster_name)

eksctl create iamserviceaccount \
--cluster="$whale_k8s_cluster_name" \
--namespace=kube-system \
--name=aws-load-balancer-controller \
--attach-policy-arn=arn:aws:iam::${whale_aws_account_id}:policy/AWSLoadBalancerControllerIAMPolicy \
--override-existing-serviceaccounts \
--approve

cat aws-lb-controller/load-balancer.yaml | \
  sed 's@--cluster-name=WHALE_CLUSTER_NAME@'"--cluster-name=${whale_k8s_cluster_name}"'@' | \
  kubectl apply -f -
```

Watch the controller pod go up via:

```
watch -d kubectl get pods -n kube-system
```


### Prepare the App's Namespace

```
kubectl create ns whale
```

### Create the Cluster Issuer for Whale

The following steps are based off of [this guide](https://cert-manager.io/docs/configuration/acme/dns01/route53/),
and [this bit of a (working) hack](https://github.com/kubernetes-sigs/aws-load-balancer-controller/issues/1084#issuecomment-725566515):

Next, let's deploy the cluster issuer in another terminal:

```
whale_dns_zone=<TYPE-IN-YOUR-FQDN-HERE>

whale_env_name=$(terraform -chdir=terraform output -raw env_name)
whale_region=$(terraform -chdir=terraform output -raw region)
whale_hosted_zone_id=$(aws route53 list-hosted-zones | \
                       jq -r ".HostedZones[] | select(.name=\"${whale_dns_zone}\") | .Id" | \
                       rev | cut -d '/' -f 1 | rev)
whale_cert_manager_role_arn=$(terraform -chdir=terraform output -raw cert_manager_role_arn)

cat cert-manager/cluster-issuer.yaml | \
  sed 's@WHALE_DNS_ZONE@'"${whale_dns_zone}"'@' | \
  sed 's@WHALE_ENV_NAME@'"${whale_env_name}"'@' | \
  sed 's@WHALE_REGION@'"${whale_region}"'@' | \
  sed 's@WHALE_HOSTED_ZONE_ID@'"${whale_hosted_zone_id}"'@' | \
  sed 's@WHALE_CERT_MANAGER_ROLE_ARN@'"${whale_cert_manager_role_arn}"'@' | \
  kubectl apply -f -
```

Check that it created the secret for our app:

```
kubectl get secret ${whale_env_name}-tls -n cert-manager
```

### What for App Events

First, lets follow events in the whale namespace to know what's happening
when we apply our manifest later:

```
kubectl get events -n whale -w
```

### Build and Deploy the UI

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

cd ..
```

In the other terminal session where you're watching events, wait for this line:

```
0s          Normal    CertificateIssued   certificaterequest/whale-prod-tls-<pod-suffix>                        Certificate fetched from issuer successfully
```

Be patient though as it can take a few minutes and you'll see errors like this:

```
Error presenting challenge: Time limit exceeded. Last error:
```

or:

```
Failed build model due to ingress: whale/ingress-whale-api: none certificate found for host: ui.whale.kubekit.io
```

Ignore those. Check the status as well via:


```
https://check-your-website.server-daten.de/?q=${component}.${whale_dns_zone}
```


### Import the Key and Cert to ACM and Add the UI FQDN to Route53

```
cd ..  # <PROJECT ROOT>

scripts/configure-tls-resources ui <DNS_ZONE-FQDN-HERE>
```

Once this script completes, the AWS LB Controller will be able to
create the ALB fronting the UI.


### Build and Deploy the API

```
cd .. # PROJECT ROOT

make api
```

In the other terminal session where you're watching events, wait for this line:

```
0s          Normal    CertificateIssued   certificaterequest/whale-prod-api-tls-<pod-suffix>                        Certificate fetched from issuer successfully
```

Be patient though as it can take a few minutes and you'll see errors like this:

```
Error presenting challenge: Time limit exceeded. Last error:
```

or:

```
Failed build model due to ingress: whale/ingress-whale-api: none certificate found for host: api.whale.kubekit.io
```

Ignore those. Check the status as well via:

```
https://check-your-website.server-daten.de/?q=${component}.${whale_dns_zone}
```


### Import the Key and Cert to ACM and Add the API FQDN to Route53

```
cd ..  # <PROJECT ROOT>

scripts/configure-tls-resources api <DNS_ZONE-FQDN-HERE>
```

Once this script completes, the AWS LB Controller will be able to
create the ALB fronting the API.


### Clean Up That Blubber!

```
cd <PROJECT-ROOT>

whale_env_name=$(terraform -chdir=terraform output -raw env_name)
whale_k8s_cluster_name=$(terraform -chdir=terraform output -raw k8s_cluster_name)
whale_aws_account_id=$(terraform -chdir=terraform output -raw account_id)

scripts/delete-tls-resources ui <DOMAIN-FQDN-HERE>

kubectl delete ns whale

kubectl delete -f aws-lb-controller/load-balancer.yaml

kubectl delete ns cert-manager

kubectl delete ns prometheus


eksctl delete iamserviceaccount \
    --cluster=$whale_k8s_cluster_name \
    --namespace=kube-system \
    --name=aws-load-balancer-controller

cat tmp/iam-policy.out | \
    jq -r '.Policy.Arn' | \
    xargs -I {} aws iam delete-policy --policy-arn {}

terraform -chdir=terraform destroy
```

Finally, if you no longer plan on bringing up this cluster at
a later point in time, clean up the following as well:

```
aws secretsmanager delete-secret \
  --force-delete-without-recovery \
  --secret-id "whale-db-creds-${whale_env_name}"

whale_zone_fqdn=<TYPE-IN-YOUR-FQDN-HERE>
whale_aws_cli_profile=$(grep -E ' *profile *=' terraform/terraform.tfvars | sed -E 's/ *profile *= *"(.*)"/\1/g')
whale_aws_region=$(grep -E ' *region *=' terraform/terraform.tfvars | sed -E 's/ *region *= *"(.*)"/\1/g')

aws route53 delete-hosted-zone \
  --profile "$whale_aws_cli_profile" \
  --name "$whale_zone_fqdn" \
  --caller-reference "$whale_route53_caller_reference" > tmp/create-hosted-zone.out
```
