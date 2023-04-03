resource "aws_s3_bucket" "foo-bucket" {
    bucket = "foo101-test-bucket"


    tags = {
        Name = "Foo bucket"
        Environment = "Dev"
    }
}

resource "aws_s3_bucket_acl" "foo-bucket-acl" {
    bucket = aws_s3_bucket.foo-bucket.id
    acl = "private"
}

# Enable Block Public Access
resource "aws_s3_bucket_public_access_block" "foo-bucket-public-access" {
    bucket = aws_s3_bucket.foo-bucket.id

    block_public_acls = true
    block_public_policy = true
    ignore_public_acls = true
    restrict_public_buckets = true
}

# Enable the versioning of the bucket.
resource "aws_s3_bucket_versioning" "foo-bucket-versioning" {
    bucket = aws_s3_bucket.foo-bucket.id

    versioning_configuration {
      status = "Enabled"
    }
}

# Set the lifecycle configuration.
# Will move current versions of objects between storage classes.
# > 30 days Standard-IA
# > 60 days Glacier
# > 90 day will receive a delete marker.
resource "aws_s3_bucket_lifecycle_configuration" "foo-bucket-lifecycle" {
    bucket = aws_s3_bucket.foo-bucket.id

    rule {
      id = "rule-1"

      expiration {
        days = 90
      }

      filter {
        prefix = ".txt"
      }

      status = "Enabled"

      transition {
        days = 30
        storage_class = "STANDARD_IA"
      }

      transition {
        days = 60
        storage_class = "GLACIER"
      }
    }
}

# Upload a file to the bucket.
resource "aws_s3_object" "foobar-object" {
    bucket = aws_s3_bucket.foo-bucket.id

    key = "foobar.txt"
    source = "./foobar.txt"

    tags = {
      "Name" = "foo"
    }
}