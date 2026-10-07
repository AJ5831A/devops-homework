variable "aws_region" {
  description = "AWS region for the demo bucket"
  type        = string
  default     = "ap-south-1"
}

variable "bucket_prefix" {
  description = "Terraform appends a unique suffix to this bucket prefix"
  type        = string
  default     = "aj5831a-devops-"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,30}-$", var.bucket_prefix))
    error_message = "Use 4–32 lowercase letters, numbers or hyphens, starting with a letter and ending in a hyphen."
  }
}
