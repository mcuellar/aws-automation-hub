resource "aws_wafv2_web_acl" "this" {
  count       = var.enable_waf ? 1 : 0
  name        = "${local.name_prefix}-waf"
  description = "AWS WAF managed protections for the serverless API."
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    dynamic "override_action" {
      for_each = upper(var.waf_override_action) == "COUNT" ? [1] : []
      content {
        count {}
      }
    }

    dynamic "override_action" {
      for_each = upper(var.waf_override_action) == "NONE" ? [1] : []
      content {
        none {}
      }
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-managed-common"
    }
  }

  visibility_config {
    sampled_requests_enabled   = true
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.name_prefix}-waf"
  }

  tags = local.tags
}

resource "aws_wafv2_web_acl_association" "api" {
  count = var.enable_waf && var.create_api_gateway ? 1 : 0

  resource_arn = aws_apigatewayv2_stage.default[0].arn
  web_acl_arn  = aws_wafv2_web_acl.this[0].arn
}
