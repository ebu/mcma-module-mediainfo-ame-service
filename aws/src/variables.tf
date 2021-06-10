#########################
# Environment Variables
#########################

variable "name" {
  type        = string
  description = "Optional variable to set a custom name for this service in the service registry"
  default     = "MediaInfo AME Service"
}

variable "prefix" {
  type        = string
  description = "Prefix for all managed resources in this module"
}

variable "stage_name" {
  type        = string
  description = "Stage name to be used for the API Gateway deployment"
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to created resources"
  default     = {}
}

variable "dead_letter_config_target" {
  type        = string
  description = "Configuring dead letter target for worker lambda"
  default     = null
}

#########################
# Output bucket
#########################

variable "output_bucket" {
  type = object({
    id = string
    arn = string
    bucket = string
  })
  description = "Optional bucket for service to write output files"
  default = null
}

variable "output_bucket_encryption_key" {
  type = object({
    id  = string
    arn = string
  })
  description = "Optional Encryption key for output bucket"
  default = null
}

variable "output_bucket_lifecycle" {
  type        = object({
    id              = string
    enabled         = bool
    expiration_days = number
  })
  description = "Optional output bucket lifecycle configuration"
  default     = {
    id              = "Delete after 7 days"
    enabled         = true
    expiration_days = 7
  }
}

variable "output_bucket_logging" {
  type        = object({
    target_bucket = string
    target_prefix = string
  })
  description = "Optional output bucket logging"
  default     = null
}
#########################
# AWS Variables
#########################

variable "aws_account_id" {
  type        = string
  description = "Account ID to which this module is deployed"
}

variable "aws_region" {
  type        = string
  description = "AWS Region to which this module is deployed"
}

variable "iam_role_path" {
  type        = string
  description = "Path for creation of access role"
  default     = "/"
}

variable "iam_policy_path" {
  type        = string
  description = "Path for creation of access policy"
  default     = "/"
}

#########################
# Dependencies
#########################

variable "service_registry" {
  type = object({
    auth_type    = string,
    services_url = string,
  })
}

#########################
# Logging
#########################

variable "log_group" {
  type        = object({
    id   = string
    arn  = string
    name = string
  })
  description = "Log group used by MCMA Event tracking"
}

variable "api_gateway_logging_enabled" {
  type        = bool
  description = "Enable API Gateway logging"
  default     = false
}

variable "api_gateway_metrics_enabled" {
  type        = bool
  description = "Enable API Gateway metrics"
  default     = false
}

variable "xray_tracing_enabled" {
  type        = bool
  description = "Enable X-Ray tracing"
  default     = false
}

variable "enhanced_monitoring_enabled" {
  type        = bool
  description = "Enable CloudWatch Lambda Insights"
  default     = false
}
