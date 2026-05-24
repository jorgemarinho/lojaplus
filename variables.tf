
variable "region" {
	description = "AWS region to deploy resources"
	type        = string
	default     = "sa-east-1"
}

variable "vpc_cidr" {
	description = "CIDR block for the VPC"
	type        = string
	default     = "10.0.0.0/16"

	validation {
		condition     = can(cidrhost(var.vpc_cidr, 0))
		error_message = "vpc_cidr must be a valid CIDR block (ex: 10.0.0.0/16)"
	}
}

variable "db_username" {
	description = "Master username for RDS"
	type        = string
	default     = "admin"
}

variable "db_password" {
	description = "Master password for RDS. If empty, a random password will be generated and stored in Secrets Manager"
	type        = string
	default     = ""
	sensitive   = true
}

variable "acm_certificate_arn" {
	description = "(Optional) ACM certificate ARN to enable HTTPS listener on the ALB. Leave empty to keep only HTTP listener."
	type        = string
	default     = ""
}
