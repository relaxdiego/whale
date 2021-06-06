#
# Control Plane Resources
#

resource "aws_iam_role" "k8s" {
  name = "${var.env_name}-k8s-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "k8s_policy_attachment1" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.k8s.name
}

resource "aws_eks_cluster" "k8s" {
  name     = "${var.env_name}-k8s"
  role_arn = aws_iam_role.k8s.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.private_subnet1.id,
      aws_subnet.private_subnet2.id
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.k8s_policy_attachment1,
  ]
}


#
# Worker Node Resources
#

resource "aws_iam_role" "k8s_node_group" {
  name = "${var.env_name}-k8s-node-group"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.k8s_node_group.name
}

resource "aws_iam_role_policy_attachment" "cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.k8s_node_group.name
}

resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.k8s_node_group.name
}

resource "aws_launch_template" "k8s" {
  name = "${var.env_name}-k8s-launch-template"
  vpc_security_group_ids = [
    aws_security_group.allow_db_access_within_vpc.id,
    aws_security_group.allow_ssh_within_vpc.id,
    aws_security_group.common_egress.id,
  ]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.env_name}-k8s-worker"
    }
  }
}

resource "aws_eks_node_group" "k8s" {
  cluster_name    = aws_eks_cluster.k8s.name
  node_group_name = "${var.env_name}-k8s-nodes"
  node_role_arn   = aws_iam_role.k8s_node_group.arn
  instance_types  = var.k8s_node_instance_types
  subnet_ids = [
    aws_subnet.private_subnet1.id,
    aws_subnet.private_subnet2.id
  ]

  launch_template {
    id      = aws_launch_template.k8s.id
    version = aws_launch_template.k8s.latest_version
  }

  scaling_config {
    desired_size = var.k8s_desired_size
    min_size     = var.k8s_min_size
    max_size     = var.k8s_max_size
  }

  # Allow external changes without causing plan diffs
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

  depends_on = [
    aws_iam_role_policy_attachment.worker_node_policy,
    aws_iam_role_policy_attachment.cni_policy,
    aws_iam_role_policy_attachment.ecr_read_only,
  ]
}
