# output "lambda_role_name" {
#   value = aws_iam_role.lambda_role.name
# }

# output "lambda_role_arn" {
#   value = aws_iam_role.lambda_role.arn
# }

# output "aws_iam_policy_lambda_logging_arn" {
#   value = aws_iam_policy.lambda_logging.arn
# }


output "aws_caller_identity" {
 value = data.aws_caller_identity.current
}


output "aws_iam_session_context" {
  value = data.aws_iam_session_context.current
}
