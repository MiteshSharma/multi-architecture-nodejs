resource "aws_ecr_repository" "repository" {
  name = var.service_name
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "random_string" "codebuild_name" {
  length  = 16
  special = false
  lower   = true
}

locals {
  codebuild_name = "${var.service_name}-image-builder-${random_string.codebuild_name.result}"
}

resource "aws_iam_role" "default" {
  name               = substr("CodeBuildRole-${local.codebuild_name}", 0, 64)
  assume_role_policy = data.aws_iam_policy_document.codebuild_role.json
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name = "default"
  role = aws_iam_role.default.name
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          Effect : "Allow",
          Resource : [
            format("arn:aws:logs:%s:%s:log-group:/aws/codebuild/%s", data.aws_region.current.name, data.aws_caller_identity.current.account_id, local.codebuild_name),
            format("arn:aws:logs:%s:%s:log-group:/aws/codebuild/%s:*", data.aws_region.current.name, data.aws_caller_identity.current.account_id, local.codebuild_name),
          ],
          Action : [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
        },
        {
          Effect : "Allow",
          Action : [
            "codebuild:CreateReportGroup",
            "codebuild:CreateReport",
            "codebuild:UpdateReport",
            "codebuild:BatchPutTestCases"
          ],
          Resource : [
            format("arn:aws:codebuild:%s:%s:report-group/%s-*", data.aws_region.current.name, data.aws_caller_identity.current.account_id, local.codebuild_name)
          ]
        }
      ]
    }
  )
}

resource "aws_codebuild_source_credential" "authorization" {
  auth_type   = "PERSONAL_ACCESS_TOKEN"
  server_type = "GITHUB"
  token       = var.github_credential_token
  user_name   = var.github_credential_user_name
}

resource "aws_codebuild_project" "default" {
  name           = local.codebuild_name
  service_role   = aws_iam_role.default.arn
  source_version = "master"

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:1.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "AWS_REGION"
      value = data.aws_region.current.name
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }

  }

  source {
    buildspec           = "buildspec.yml"
    type                = "GITHUB"
    location            = var.github_repository_url
    report_build_status = true
  }

  logs_config {
    cloudwatch_logs {
    }
  }


}

resource "aws_codebuild_webhook" "hook" {
  project_name = aws_codebuild_project.default.name
  build_type   = "BUILD"
  filter_group {
    filter {
      type    = "EVENT"
      pattern = "PUSH"
    }

    filter {
      type    = "HEAD_REF"
      pattern = "master"
    }
  }
}
