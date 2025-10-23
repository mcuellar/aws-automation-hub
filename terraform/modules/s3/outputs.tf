output "bucket_id" {
  description = "The bucket ID (name)"
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "The bucket ARN"
  value       = aws_s3_bucket.this.arn
}

output "bucket_domain_name" {
  description = "Bucket domain name"
  value       = aws_s3_bucket.this.bucket_domain_name
}
