# Gateway and Key

resource "aws_api_gateway_rest_api" "lambda_api_gateway" {
    count = var.use_api_gateway ? 1 : 0

    name = var.full_stack_name
    api_key_source = "HEADER"
    endpoint_configuration {
        types = ["REGIONAL"]
    }
}

resource "aws_api_gateway_api_key" "lambda_api_gateway_api_key" {
    count = var.use_api_gateway ? 1 : 0

    name = "${var.full_stack_name}Key"
}

# Stage

resource "aws_api_gateway_deployment" "lambda_api_gateway_deployment" {
    count = var.use_api_gateway ? 1 : 0

    rest_api_id = aws_api_gateway_rest_api.lambda_api_gateway[0].id

    depends_on = [
        aws_api_gateway_method.lambda_api_gateway_method,
        aws_api_gateway_integration.lambda_api_gateway_integration
    ]
}

resource "aws_api_gateway_stage" "lambda_api_gateway_stage" {
    count = var.use_api_gateway ? 1 : 0

    deployment_id = aws_api_gateway_deployment.lambda_api_gateway_deployment[0].id
    rest_api_id = aws_api_gateway_rest_api.lambda_api_gateway[0].id
    stage_name = var.stack_env
}

# Usage Plan

resource "aws_api_gateway_usage_plan" "lambda_api_usage_plan" {
    count = var.use_api_gateway ? 1 : 0

    name = "${var.full_stack_name}UsagePlan"
    api_stages {
        api_id = aws_api_gateway_rest_api.lambda_api_gateway[0].id
        stage = aws_api_gateway_stage.lambda_api_gateway_stage[0].stage_name
    }
}

resource "aws_api_gateway_usage_plan_key" "lambda_api_usage_plan_key" {
    count = var.use_api_gateway ? 1 : 0

    key_id = aws_api_gateway_api_key.lambda_api_gateway_api_key[0].id
    key_type = "API_KEY"
    usage_plan_id = aws_api_gateway_usage_plan.lambda_api_usage_plan[0].id
}

# Endpoint Definitions

resource "aws_api_gateway_resource" "lambda_api_gateway_resource_segment_one" {
    for_each = tomap(var.segment_one_resources)

    rest_api_id = aws_api_gateway_rest_api.lambda_api_gateway[0].id
    parent_id = aws_api_gateway_rest_api.lambda_api_gateway[0].root_resource_id
    path_part = each.value.path_part
}

resource "aws_api_gateway_resource" "lambda_api_gateway_resource_segment_two" {
    for_each = tomap(var.segment_two_resources)

    rest_api_id = aws_api_gateway_rest_api.lambda_api_gateway[0].id
    parent_id = length(each.value.parent_resource) > 0 ? aws_api_gateway_resource.lambda_api_gateway_resource_segment_one[each.value.parent_resource].id : aws_api_gateway_rest_api.lambda_api_gateway[0].root_resource_id
    path_part = each.value.path_part
}

resource "aws_api_gateway_method" "lambda_api_gateway_method" {
    for_each = tomap(var.actions)

    rest_api_id = aws_api_gateway_rest_api.lambda_api_gateway[0].id
    resource_id = each.key == "root" ? aws_api_gateway_rest_api.lambda_api_gateway[0].root_resource_id : each.value.segment == 1 ? aws_api_gateway_resource.lambda_api_gateway_resource_segment_one[each.key].id : each.value.segment == 2 ? aws_api_gateway_resource.lambda_api_gateway_resource_segment_two[each.key].id : ""
    http_method = each.value.method
    api_key_required = each.value.api_key_required
    authorization = each.value.auth
}

# Endpoint Integration

resource "aws_api_gateway_integration" "lambda_api_gateway_integration" {
    for_each = tomap(var.actions)

    rest_api_id = aws_api_gateway_rest_api.lambda_api_gateway[0].id
    resource_id = each.key == "root" ? aws_api_gateway_rest_api.lambda_api_gateway[0].root_resource_id : each.value.segment == 1 ? aws_api_gateway_resource.lambda_api_gateway_resource_segment_one[each.key].id : each.value.segment == 2 ? aws_api_gateway_resource.lambda_api_gateway_resource_segment_two[each.key].id : ""
    http_method = each.value.method
    integration_http_method = "POST"
    type = "AWS_PROXY"
    uri = aws_lambda_function.lambda_function[each.value.function].invoke_arn
}

resource "aws_lambda_permission" "lambda_api_gateway_integration_permission" {
    for_each = tomap(var.actions)

    statement_id  = "AllowInvoke${each.key}"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.lambda_function[each.value.function].function_name
    principal = "apigateway.amazonaws.com"
    source_arn = "arn:aws:execute-api:eu-west-2:${var.aws_account_id}:${aws_api_gateway_rest_api.lambda_api_gateway[0].id}/*/${each.value.method}/${each.value.full_path}"
}

resource "aws_api_gateway_rest_api_policy" "api_policy" {
    count = length(var.access_policy) > 0 ? 1 : 0

    rest_api_id = aws_api_gateway_rest_api.lambda_api_gateway[0].id
    policy = var.access_policy
}

# Custom domain

resource "aws_api_gateway_domain_name" "custom_domain" {
    count = length(var.domain_name) > 0 ? 1 : 0

    domain_name = var.domain_name
    regional_certificate_arn = var.domain_certificate_arn

    endpoint_configuration {
        types = ["REGIONAL"]
    }
}

resource "aws_api_gateway_base_path_mapping" "custom_domain_base_path" {
    count = length(var.domain_name) > 0 ? 1 : 0

    api_id = aws_api_gateway_rest_api.lambda_api_gateway[0].id
    domain_name = aws_api_gateway_domain_name.custom_domain[0].domain_name
    stage_name = aws_api_gateway_stage.lambda_api_gateway_stage[0].stage_name
}

resource "aws_route53_record" "custom_domain_a_record" {
    count = length(var.domain_name) > 0 ? 1 : 0

    name = aws_api_gateway_domain_name.custom_domain[0].domain_name
    type = "A"
    zone_id = var.domain_zone_id

    alias {
        evaluate_target_health = true
        name = aws_api_gateway_domain_name.custom_domain[0].regional_domain_name
        zone_id = aws_api_gateway_domain_name.custom_domain[0].regional_zone_id
    }
}
