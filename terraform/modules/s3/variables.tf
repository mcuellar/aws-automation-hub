variable "name" {
  description = "Name of the S3 bucket. If omitted, Terraform will generate a unique name when create_unique_bucket is true."
  type        = string
  default     = null
}

variable "create_unique_bucket" {
  description = "If true and name is null, create a bucket with a generated unique name. If false, name must be provided."
  type        = bool
  default     = true
}

variable "acl" {
  description = "Canned ACL to apply to the bucket"
  type        = string
  default     = "private"
}

variable "versioning_enabled" {
  description = "Enable S3 versioning"
  type        = bool
  default     = false
}

variable "force_destroy" {
  description = "A boolean that indicates all objects should be deleted from the bucket so that the bucket can be destroyed without error."
  type        = bool
  default     = false
}

variable "block_public_acls" {
  description = "Whether to block public ACLs"
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "Whether to block public bucket policies"
  type        = bool
  default     = true
}

variable "ignore_public_acls" {
  description = "Whether to ignore public ACLs"
  type        = bool
  default     = true
}

variable "restrict_public_buckets" {
  description = "Whether to restrict public buckets"
  type        = bool
  default     = true
}

variable "server_side_encryption" {
  description = "Server side encryption configuration. Allowed values: \"AES256\" or KMS key ARN or null"
  type        = string
  default     = null
}

variable "lifecycle_rules" {
  description = "List of lifecycle rules to apply to the bucket (as a list of maps)"
  type = list(object({
    id      = optional(string)
    enabled = optional(bool, true)
    prefix  = optional(string)
    tags    = optional(map(string))
    transitions = optional(list(object({
      days          = optional(number)
      storage_class = optional(string)
    })), [])
    expiration = optional(object({ days = optional(number) }), null)
    noncurrent_version_expiration = optional(object({ days = optional(number) }), null)
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to the bucket"
  type        = map(string)
  default     = {}
}

variable "kms_key_id" {
  description = "Optional KMS Key ID/ARN to use for SSE-KMS. If provided, server_side_encryption should be \"aws:kms\" or the ARN."
  type        = string
  default     = null
}

variable "region" {
  description = "Optional region provider override. Most users should configure provider in root module."
  type        = string
  default     = null
}
