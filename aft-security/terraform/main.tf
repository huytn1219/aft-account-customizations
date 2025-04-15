########################################
#######   AFT Core Parameters    #######
########################################
resource "aws_ssm_parameter" "account_id" {
  # checkov:skip=CKV_AWS_337:This SSM parameter is not a SecureString and there is no need to encrypt it using KMS
  # checkov:skip=CKV2_AWS_34:This SSM parameter is not a SecureString and there is no need to encrypt it using KMS
  name        = "/org/core/accounts/ct-security-tooling"
  type        = "String"
  description = "Control Tower Security Tooling account Id"
  value       = data.aws_caller_identity.current.account_id
  tags        = local.tags
}

############################################
#######     GuardDuty delegation     #######
############################################
resource "aws_guardduty_organization_admin_account" "main" {

  admin_account_id = data.aws_caller_identity.current.account_id
}

########################################
#######         GuardDuty        #######
########################################
module "guardduty" {
  source     = "../../common/modules/security/guardduty"
  depends_on = [aws_guardduty_organization_admin_account.main]

  datasources = var.datasources

  organization_features = var.organization_features

  additional_configuration = var.additional_configuration

  auto_enable_organization_members = var.guardduty_auto_enable_organization_members

  enabled_export_to_s3 = true

  guard_duty_s3_bucket_arn = data.aws_ssm_parameter.guard_duty_bucket_for_logs.value

  guard_duty_kms_arn = data.aws_ssm_parameter.guard_duty_kms_for_logs.value
}