data "aws_secretsmanager_secret_version" "db_creds" {
  secret_id = var.db_creds_secret_name
}

locals {
  db_creds = jsondecode(
    data.aws_secretsmanager_secret_version.db_creds.secret_string
  )
  db_name = replace(title(replace("${var.env_name}-db", "-", " ")), " ", "")
}


resource "aws_db_subnet_group" "db" {
  name = "${var.env_name}-db"
  subnet_ids = [
    aws_subnet.private_subnet1.id,
    aws_subnet.private_subnet2.id
  ]

  tags = {
    Name = "${var.env_name}-db"
  }
}

resource "aws_db_instance" "db" {
  # identifier           = local.db_name
  allocated_storage    = 20
  engine               = "postgres"
  instance_class       = "db.t2.micro"
  name                 = local.db_name
  db_subnet_group_name = "${var.env_name}-db"
  username             = local.db_creds.db_user
  password             = local.db_creds.db_pass

  # Commenting out to save on cost, yo!
  # multi_az             = true

  # Comment out the following in a production environment, yo!
  skip_final_snapshot = true

  depends_on = [aws_db_subnet_group.db]
}
