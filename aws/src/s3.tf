resource "aws_s3_bucket" "output" {
  bucket        = "${var.prefix}-output-${var.aws_region}"
  acl           = "private"
  force_destroy = true

  dynamic "server_side_encryption_configuration" {
    for_each = var.output_bucket_encryption_key != null ? toset([1]) : toset([])

    content {
      rule {
        apply_server_side_encryption_by_default {
          kms_master_key_id = var.output_bucket_encryption_key.arn
          sse_algorithm     = "aws:kms"
        }
      }
    }
  }

  dynamic "lifecycle_rule" {
    for_each = var.output_bucket_lifecycle != null ? toset([1]) : toset([])

    content {
      id      = var.output_bucket_lifecycle.id
      enabled = var.output_bucket_lifecycle.enabled
      expiration {
        days = var.output_bucket_lifecycle.expiration_days
      }
    }
  }

  dynamic "logging" {
    for_each = var.output_bucket_logging != null ? toset([1]) : toset([])

    content {
      target_bucket = var.output_bucket_logging.target_bucket
      target_prefix = var.output_bucket_logging.target_prefix
    }
  }

  tags = var.tags

  count = var.output_bucket == null ? 1 : 0
}

resource "aws_s3_bucket_public_access_block" "output" {
  bucket = aws_s3_bucket.output[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  count = var.output_bucket == null ? 1 : 0
}
