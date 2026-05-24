resource "aws_db_subnet_group" "db" {
  name       = "lojaplus-db-subnet"
  subnet_ids = aws_subnet.db[*].id
}
# If user provided var.db_password use it; otherwise generate a random password
resource "random_password" "db" {
  count           = var.db_password == "" ? 1 : 0
  length          = 16
  override_characters = "@#-!"
}
resource "aws_secretsmanager_secret" "db_password" {
  count = var.db_password == "" ? 1 : 0

  name = "lojaplus/db_password"
}
resource "aws_secretsmanager_secret_version" "db_password" {
  count      = var.db_password == "" ? 1 : 0
  secret_id  = aws_secretsmanager_secret.db_password[0].id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db[0].result
  })
}
locals {
  db_password_value = var.db_password != "" ? var.db_password : random_password.db[0].result
}
resource "aws_db_instance" "primary" {
  identifier             = "lojaplus-db"
  engine                 = "postgres"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  username               = var.db_username
  password               = local.db_password_value
  db_subnet_group_name   = aws_db_subnet_group.db.name
  vpc_security_group_ids = [aws_security_group.db.id]
  multi_az               = true
}
resource "aws_db_instance" "replica" {
  replicate_source_db = aws_db_instance.primary.id
  instance_class      = "db.t3.micro"
}
output "db_password_secret_arn" {
  description = "ARN of the Secrets Manager secret created for DB password (if generated)."
  value       = try(aws_secretsmanager_secret.db_password[0].arn, "")
}

resource "aws_db_subnet_group" "db" {
  name       = "lojaplus-db-subnet"
  subnet_ids = aws_subnet.db[*].id
}

# If user provided var.db_password use it; otherwise generate a random password
resource "random_password" "db" {
  count           = var.db_password == "" ? 1 : 0
  length          = 16
  override_characters = "@#-!"
}

resource "aws_secretsmanager_secret" "db_password" {
  count = var.db_password == "" ? 1 : 0

  name = "lojaplus/db_password"
}

resource "aws_secretsmanager_secret_version" "db_password" {
  count      = var.db_password == "" ? 1 : 0
  secret_id  = aws_secretsmanager_secret.db_password[0].id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db[0].result
  })
}

locals {
  db_password_value = var.db_password != "" ? var.db_password : random_password.db[0].result
}

resource "aws_db_instance" "primary" {
  identifier             = "lojaplus-db"
  engine                 = "postgres"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  username               = var.db_username
  password               = local.db_password_value
  db_subnet_group_name   = aws_db_subnet_group.db.name
  vpc_security_group_ids = [aws_security_group.db.id]
  multi_az               = true
}

resource "aws_db_instance" "replica" {
  replicate_source_db = aws_db_instance.primary.id
  instance_class      = "db.t3.micro"
}

output "db_password_secret_arn" {
  description = "ARN of the Secrets Manager secret created for DB password (if generated)."
  value       = try(aws_secretsmanager_secret.db_password[0].arn, "")
}
