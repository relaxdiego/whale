# Give this environment a name
env_name = "whale-prod"

# AWS CLI config profile
profile = "personal"

region = "us-west-2"

vpc_cidr_block = "10.10.0.0/16"

# Public key to inject in instances created in the VPC
authorized_key_name = "mmaglana"
authorized_key      = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDSaDjzC7ODr2URU2K+5Gp6BhlONmK9LWHyFCcyNI2klseDWuMDyAdhFGuoc7VutyfJpCoc+RqRRVOoFN4oogYXZgDgFKH6zdXmMNSuu4OhgoCOfWmz6tF6WssgP6SsgJz8pT6LWsk5lg7hbuIxhWbhHZBhSJCTeymIEJT2HtgjK0/9o3Rw897UO/IuIqXhPpI3sKhI30dJcGho8JGw1UrGfHhmaJ9fW8oBAv+xhZ0vv6OdjZYroqI/iolFTbLkZ0Qd8xK78F9JQ1QoEl3hNbsMJqmbbtoy6Lha7wn+aiWHb0latcCDxQtFO/uCppPcTOQiwQ5R3rXKtC8/koj1aQxdezxq+izpkM4Aasrr9WlJxXt6ZnAUYuPCrGWy1FziEW1yDm54bhSCiM7MEESea5sKvHSkDwvbExeeV9y7uPkDltDQnxUZ+aKRejaxZLJbPsVV09FWZvJw5xSi0n633DRMvB6ZL+BXJy4sdyGdEJ6/rpVDdNXT958hfUjXl8dFWXBgqladUl91Bpjr4XqtWqiyzdjGrEPynTsvZYZHtfn9+WUFIavGJMiGB78Cv2YKxsHsRy+p36ihLgEHRqXcbNAEb0kzNufCBlmbtbKoYZ9Hp2Hhx3lvR9ZYzRiidh8vqFMMlUlZ+Zgw8S8r3ycHviGOsBQ9iPHWvWz3ZT4zaBHtFQ== for questions pls email mark.maglana@linux.com"

public_subnet1_cidr_block        = "10.10.11.0/24"
public_subnet1_availability_zone = "us-west-2a"
public_subnet2_cidr_block        = "10.10.12.0/24"
public_subnet2_availability_zone = "us-west-2b"

# NOTE: Private subnets are automatically placed in the same availability
#       zone as their public counterparts.
private_subnet1_cidr_block = "10.10.21.0/24"
private_subnet2_cidr_block = "10.10.22.0/24"

db_creds_secret_name   = "whale-prod-db-credentials"
db_multi_az            = true
db_skip_final_snapshot = false

k8s_desired_size        = 2
k8s_max_size            = 5
k8s_min_size            = 1
k8s_node_instance_types = ["t3.medium"]
