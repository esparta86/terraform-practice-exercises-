
terraform {

   required_providers {
     aws = {
      source = "hashicorp/aws"
      version = "~>4.0"
     }
   }

  backend "s3" {
    bucket = "colocho86-tf-states"
    key = "demo-aws-lambda/s3/terraform.tfstate"
    region = "us-east-1"

    dynamodb_table = "terraform-locks"
    encrypt = true
  }

}

provider "aws" {

  region  = var.aws_region
  profile = "personal"
  assume_role {
    role_arn = "arn:aws:iam::734237051973:role/github-role"
  }
}


resource "aws_s3_bucket" "lambda_bucket" {
  bucket = "lambda-bucket-colocho2022"

  acl           = "private"
  force_destroy = true
}



# data "archive_file" "lambda_nodeapp_archive" {
#   type = "zip"
#   source_dir = "${path.cwd}/nodejs-app"
#   output_path = "${path.cwd}/nodeApp.zip"
# }


resource "aws_s3_object" "lambda_nodeapp_object" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key = "lambda-artifacts/nodeapp/nodeAppv2.zip"
  # source = data.archive_file.lambda_nodeapp_archive.output_path
  source = "${path.cwd}/myzip/nodeAppv2.zip"

  # etag =filemd5(data.archive_file.lambda_nodeapp_archive.output_path)
  etag = filemd5("${path.cwd}/myzip/nodeAppv2.zip")

  depends_on = [
    aws_s3_bucket.lambda_bucket
  ]
}


resource "aws_lambda_function" "nodeapp" {
    function_name = "nodeapp"
    s3_bucket = aws_s3_bucket.lambda_bucket.id
    s3_key = aws_s3_object.lambda_nodeapp_object.key

    runtime = "nodejs16.x"

    handler = "index.handler"

    # source_code_hash = data.archive_file.lambda_nodeapp_archive.output_base64sha256
    source_code_hash = filebase64sha256("${path.cwd}/myzip/nodeAppv2.zip")
    role = aws_iam_role.lambda_exec.arn

  lifecycle {
    ignore_changes = [
      s3_bucket,
      s3_key,
      s3_object_version,
      source_code_hash,
      last_modified,   # add this too — it's flapping in your plan
      publish,
    ]
  }
}


resource "aws_cloudwatch_log_group" "nodeapp" {
  name = "/aws/lambda/${aws_lambda_function.nodeapp.function_name}"

  retention_in_days = 30

  depends_on = [
    aws_lambda_function.nodeapp
  ]
}

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}






# resource "aws_iam_role" "lambda_role" {
#   name = "iam_role_lambda_function"

#   assume_role_policy = jsonencode({
#     "Version" : "2012-10-17"
#     "Statement" : [
#       {
#         "Action" : "sts:AssumeRole",
#         "Principal" : {
#           "Service" : "lambda.amazonaws.com"
#         },
#         "Effect" : "Allow",
#         "Sid" : ""
#       }
#     ]
#   })
#   tags = {
#     tag-key = "roleLambda"
#   }
# }

# resource "aws_iam_policy" "lambda_logging" {
#   name        = "iam_policy_lamba_logging_function"
#   path        = "/"
#   description = "IAM policy for logging from lambda"
#   policy      = <<EOF
# {
# 	"Version": "2012-10-17",
# 	"Statement": [{
# 		"Action": [
# 			"logs:CreateLogGroup",
# 			"logs:CreateLogStream",
# 			"logs:PutLogEvents"
# 		],
# 		"Resource": "arn:aws:logs:*:*",
# 		"Effect": "Allow"
# 	}]
# }
#     EOF
# }


# resource "aws_iam_role_policy_attachment" "policy_attach" {
#   role       = aws_iam_role.lambda_role.name
#   policy_arn = aws_iam_policy.lambda_logging.arn
# }

# # It generates an archive from content, a file or directory of files
# data "archive_file" "default" {
#   type        = "zip"
#   source_dir  = "${path.module}/files/"
#   output_path = "${path.module}/myzip/python.zip"
# }

# #Create a lambda function
# # In terraform ${path.module} is the current directory.

# resource "aws_lambda_function" "lambdafunc" {
#   filename      = "${path.module}/myzip/python.zip"
#   function_name = "My_Lambda_function"
#   role          = aws_iam_role.lambda_role.arn
#   handler       = "index.lambda_handler"
#   runtime       = "python3.8"
#   depends_on = [
#     aws_iam_role_policy_attachment.policy_attach
#   ]

# }
