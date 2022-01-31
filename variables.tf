variable "actions" {
    default = {}
}
variable "segment_two_resources" {
    default = {}
}
variable "segment_one_resources" {
    default = {}
}
variable "use_api_gateway" {
    default = false
}
variable "functions" {}
variable "full_stack_name" {}
variable "stack_name" {}
variable "stack_env" {}

variable "aws_account_id" {}

variable "files_to_exclude_from_zip" {
    default = [
        "terraform",
        "Tests",
        "Dockerfile",
        "Docker",
        "README.md",
        "LICENSE.txt",
        "phpunit.xml",
        "phpstan.neon",
        "phpcs.xml",
        "climb-testing.php",
        ".phpunit.result.cache",
        ".gitlab-ci.yml",
        ".editorconfig",
        ".env.dist",
        ".env.ci",
        ".env",
        ".gitlab",
        ".idea",
        ".git",
        "server.php",
        ".env.stage",
        ".gitignore",
        "serverless.yml",
        ".serverless",
        ".directory",
    ]
}

variable "access_policy" {
    default = ""
}

variable "domain_name" {
    default = ""
}
variable "domain_zone_id" {
    default = ""
}
variable "domain_certificate_arn" {
    default = ""
}