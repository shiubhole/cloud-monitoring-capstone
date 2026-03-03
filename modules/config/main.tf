data "aws_caller_identity" "current" {}

resource "random_id" "rand" {
  byte_length = 4
}
resource "aws_s3_bucket" "config_bucket" {
  bucket = "aws-config-logs-${random_id.rand.hex}"
   force_destroy = true
   
   tags = {
    Name = "AWSConfigLogs"
  }
}

resource "aws_s3_bucket_policy" "config_bucket_policy" {
  bucket = aws_s3_bucket.config_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [

      {
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.config_bucket.arn
      },

      {
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.config_bucket.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}


resource "aws_iam_role" "config_role" {
  name = "aws-config-role-${random_id.rand.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"
      Principal = { Service = "config.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })

}

resource "aws_iam_role_policy_attachment" "config_policy" {
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}




resource "aws_config_configuration_recorder" "recorder" {
  name     = "config-recorder"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported = true
  }
}

resource "aws_config_configuration_recorder_status" "recorder_status" {
  name       = aws_config_configuration_recorder.recorder.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.delivery_channel]
}

resource "aws_config_delivery_channel" "delivery_channel" {
  name           = "config-delivery-channel"
  s3_bucket_name = aws_s3_bucket.config_bucket.bucket

  depends_on = [aws_config_configuration_recorder.recorder]
}





resource "aws_config_config_rule" "ebs_encrypted" {
  name = "ebs-encrypted-check"

  source {
    owner             = "AWS"
    source_identifier = "ENCRYPTED_VOLUMES"
  }

  depends_on = [aws_config_configuration_recorder_status.recorder_status]
}

resource "aws_config_config_rule" "required_tags" {
  name = "required-tags-check"

  source {
    owner             = "AWS"
    source_identifier = "REQUIRED_TAGS"
  }
   depends_on = [
  aws_config_configuration_recorder.recorder,
  aws_config_configuration_recorder_status.recorder_status,
  aws_config_delivery_channel.delivery_channel
]
  input_parameters = jsonencode({
    tag1Key = "Environment"
    tag2Key = "Owner"
  })
}