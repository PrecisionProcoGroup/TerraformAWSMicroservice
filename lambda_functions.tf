resource "aws_lambda_function" "lambda_function" {
    for_each = tomap(var.functions)

    function_name = each.key
    s3_bucket = aws_s3_bucket.lambda_bucket.id
    s3_key = aws_s3_bucket_object.lambda_bucket_object.key
    runtime = each.value.runtime
    handler = each.value.handler
    source_code_hash = data.archive_file.lambda_archive.output_base64sha256
    role = each.value.role
    timeout = each.value.timeout
    layers = each.value.layers
    tags = {
        env = var.stack_env
        appName = var.stack_name
    }
    vpc_config {
        security_group_ids = each.value.security_group_ids
        subnet_ids = each.value.subnet_ids
    }
    environment {
        variables = each.value.env_vars
    }
}
