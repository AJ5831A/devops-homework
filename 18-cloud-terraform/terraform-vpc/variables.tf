variable "aws_region" {
  description = "Deployment region"
  type        = string
  default     = "ap-south-1"
}

variable "instance_type" {
  description = "x86_64 EC2 type compatible with the selected AMI"
  type        = string
  default     = "t3.micro"
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
