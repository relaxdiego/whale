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
