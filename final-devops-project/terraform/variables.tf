variable "aws_region" {
  description = "Deployment region"
  type        = string
  default     = "ap-south-1"
}

variable "instance_type" {
  description = "x86_64 EC2 type compatible with the selected AMI"
  type        = string
  default     = "t3.small"
}

variable "http_cidr" {
  description = "IPv4 CIDR allowed to access HTTP; use your public IP /32"
  type        = string
  validation {
    condition     = can(cidrnetmask(var.http_cidr))
    error_message = "Supply a valid IPv4 CIDR, such as your public IPv4 address followed by /32."
  }
}

variable "bucket_prefix" {
  description = "Unique bucket prefix; provider appends a random suffix"
  type        = string
  default     = "aj5831a-cloud-lab-"
}

variable "admin_cidr" {
  description = "Administrator public IPv4 /32 for SSH and Kubernetes API"
  type        = string
  validation {
    condition     = can(cidrnetmask(var.admin_cidr)) && can(regex("/32$", var.admin_cidr)) && var.admin_cidr != "0.0.0.0/32"
    error_message = "Use your administrator's public IPv4 /32, never an unrestricted network."
  }
}

variable "key_pair_name" {
  description = "Existing EC2 key pair name in this region; keep its private key local"
  type        = string
}
