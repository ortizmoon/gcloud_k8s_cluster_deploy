variable "project_id" {
  type    = string
}

variable "region" {
  type    = string
}

variable "zone" {
  type    = string
}

variable "ssh_creds" {
  description = "SSH user:pubkey, user:ssh-ed25519 AbcdEfGhIgklMnoPqWXYZ1234567890Abc+AbcdEfGhIgklMnoPqWXYZ for example "
  type    = string
}

variable "ip_cidr_range" {
  description = "VPC range, 10.0.1.0/24 for example "
  type    = string
}


