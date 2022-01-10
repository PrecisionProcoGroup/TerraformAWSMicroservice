# Terraform AWS Microservice Module

A module for terraform to attempt to make deploying a microservice to lambda easier.

This mostly replicates the functionality of the serverless platform bar 1 main feature still in the works.

TODO:

- Custom domain functionality

The benefits of using terraform over serverless is its much, much faster and far more customizable to your specific needs.

## Usage

You can use the module similar to the example below.

> Please be aware all the information from the example below has
been stripped of sensitive data and some variables in the example are expected to come from your terraform variables. 
This assumes knowledge of how terraform works.

```terraform
terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 3.69.0"
        }
        archive = {
            source = "hashicorp/archive"
            version = "~> 2.2.0"
        }
    }
}

provider "aws" {
    region = "eu-west-2"
}

locals {
    stack_name = "myCoolStack"
    full_stack_name = join(
        "",
        [var.STACK_ENV, title(local.stack_name)]
    )
}

module "terraform-aws-microservice" {
    source = "github.com/PrecisionProcoGroup/TerraformAWSMicroservice"

    stack_env = var.STACK_ENV
    stack_name = local.stack_name
    full_stack_name = local.full_stack_name
    aws_account_id = var.AWS_ACCOUNT_ID

    # Lambda Functions
    functions = {
        "${local.full_stack_name}ExampleAction" = {
            runtime = "provided.al2"
            handler = "Handlers/example-action-handler.php"
            role = "arn:aws:iam::${var.AWS_ACCOUNT_ID}:role/myRoleToApplyToLambdas"
            timeout = 28
            layers = [
                var.layer_php_8, # ARN pointing to the layers you wish to use, for example bref for php
            ]
            security_group_ids = [
                "sg-1337", # Security groups to apply to the lambda VPC
            ]
            subnet_ids = [
                "subnet-1337", # Subnets to apply to the lambda VPC
            ]
            env_vars = {
                DB_HOST = var.DB_HOST
                DB_PORT = var.DB_PORT
                DB_DATABASE = var.DB_DATABASE
                DB_USERNAME = var.DB_USERNAME
                DB_PASSWORD = var.DB_PASSWORD
                DB_CHARSET = var.DB_CHARSET
            }
        }
    }

    # The below config is for the API gateway
  
    use_api_gateway = true

    # Resources positioned at segment 1 of the url
    segment_one_resources = {
        exampleCollection = {
            path_part = "example"
        }
    }

    # Resources positioned at segment 2 of the url
    segment_two_resources = {
        "exampleAction" = {
            path_part = "{id}"
            parent_resource = "exampleCollection" # Which segment 1 resource this belongs to  
        }
    }

    # Actions attached to a resource at segment 2 of the url which link to a lambda function
    actions = {
        exampleAction = {
            method = "GET"
            api_key_required = true
            auth = "NONE"
            function = "${local.full_stack_name}ExampleAction"
            segment = 2 # Which segment is the final resource of the url of the action  
            full_path = "example/{id}" # the full path to the action, without a leading forward slash
        }
    }
}
```

