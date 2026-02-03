resource "aws_s3_bucket" "threetierproject" {
  bucket = "threetierprojectbysamar26"
    tags = {
      Name        = "threetierprojectbysamar26"
      Environment = "Dev"
    }
}

resource "aws_s3_bucket_public_access_block" "allow_public" {
  bucket = aws_s3_bucket.threetierproject.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
