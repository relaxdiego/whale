output "env_name" {
  value = var.env_name
}

output "region" {
  value = var.region
}

output "bastion1_instance_id" {
  value       = aws_instance.bastion1.id
  description = "Use this with github.com/relaxdiego/ssh4realz to ssh to the bastion for the first time"
}

output "bastion1_public_ip" {
  value = aws_instance.bastion1.public_ip
}

output "db_endpoint" {
  value = aws_db_instance.db.endpoint
}

output "db_name" {
  value = aws_db_instance.db.name
}

output "k8s_cluster_name" {
  value = aws_eks_cluster.k8s.name
}

output "k8s_cluster_arn" {
  value = aws_eks_cluster.k8s.arn
}

output "k8s_endpoint" {
  value = aws_eks_cluster.k8s.endpoint
}

output "k8s_cacert_data" {
  value = aws_eks_cluster.k8s.certificate_authority[0].data
}
