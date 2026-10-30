data "aws_iam_policy_document" "trust" {
  for_each = {
    # Applies only ever come from main.
    deploy = "repo:${var.github_repository}:ref:refs/heads/main"
    # Pull requests from the repo's own branches; forks get no OIDC token.
    plan = "repo:${var.github_repository}:pull_request"
  }

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.github_oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [each.value]
    }
  }
}

resource "aws_iam_role" "github" {
  for_each = data.aws_iam_policy_document.trust

  name                 = "${substr(local.repo_slug, 0, 50)}-${each.key}"
  description          = "GitHub Actions ${each.key} for ${var.github_repository}"
  assume_role_policy   = each.value.json
  max_session_duration = 3600
}

# Plans read everything, change nothing, and run with -lock=false.
resource "aws_iam_role_policy_attachment" "plan" {
  role       = aws_iam_role.github["plan"].name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Deploys manage only this site: its state, its bucket, its zone's records, and the
# CloudFront and ACM resources in front of it.
data "aws_iam_policy_document" "deploy" {
  statement {
    sid       = "State"
    actions   = ["s3:ListBucket", "s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = [aws_s3_bucket.state.arn, "${aws_s3_bucket.state.arn}/*"]
  }

  statement {
    sid       = "SiteBucket"
    actions   = ["s3:*"]
    resources = ["arn:aws:s3:::${local.site_bucket_prefix}*"]
  }

  statement {
    sid       = "Records"
    actions   = ["route53:ChangeResourceRecordSets"]
    resources = [data.aws_route53_zone.site.arn]
  }

  statement {
    sid       = "Route53Read"
    actions   = ["route53:Get*", "route53:List*"]
    resources = ["*"]
  }

  # CloudFront has little resource-level scoping, and the distribution, OAC and policies
  # are created by this stack, so their ARNs aren't known up front.
  statement {
    sid       = "CloudFront"
    actions   = ["cloudfront:*"]
    resources = ["*"]
  }

  statement {
    sid       = "Certificates"
    actions   = ["acm:*"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = ["us-east-1"]
    }
  }
}

resource "aws_iam_role_policy" "deploy" {
  name   = "deploy-site"
  role   = aws_iam_role.github["deploy"].id
  policy = data.aws_iam_policy_document.deploy.json
}
