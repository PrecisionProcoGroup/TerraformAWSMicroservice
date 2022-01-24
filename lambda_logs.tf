resource "aws_cloudwatch_log_group" "lambda_function_logs" {
    for_each = tomap(var.functions)

    name = "/aws/lambda/${aws_lambda_function.lambda_function[each.key].function_name}"
    retention_in_days = 30
}

resource "aws_iam_role" "lambda_function_exec" {
    name = "${var.full_stack_name}_lambda_exec"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Sid = ""
            Principal = {
                Service = "lambda.amazonaws.com"
            }
        }]
    })
}

resource "aws_iam_role_policy_attachment" "lambda_function_policy" {
    role = aws_iam_role.lambda_function_exec.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
