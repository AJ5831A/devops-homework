output "bucket_name" {
  description = "Globally unique S3 bucket name"
  value       = aws_s3_bucket.demo.id
}

output "bucket_arn" {
  description = "ARN for IAM policy references"
  value       = aws_s3_bucket.demo.arn
}
