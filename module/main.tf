## Fetch the ARN for sso admin instance 
data "aws_ssoadmin_instances" "control_tower_che" {}

## Fetches organization details. Can be used to programatically fetch AWS account details under the AWS organization
data "aws_organizations_organization" "org_che" {}


# Get instance arn for the Permission Set 
data "aws_ssoadmin_permission_set" "control_tower_readonly" {
  instance_arn = tolist(data.aws_ssoadmin_instances.control_tower_che.arns)[0]
  name         = "Che-PS-AdministratorAccess"
}

# Creates a new permission set using the existing one 
resource "aws_ssoadmin_permission_set" "delivery_pipelines_readonly" {
  instance_arn = tolist(data.aws_ssoadmin_instances.control_tower_che.arns)[0]
  name         = "DeliveryPipelinesReadOnly"
  description  = "For delivery teams needing to see what fails and how in delivery pipelines."
}

# Creates a managed policy and attaches it to an existing permission set 
resource "aws_ssoadmin_managed_policy_attachment" "delivery_pipelines_policies" {
  for_each           = toset(["arn:aws:iam::aws:policy/AWSCodePipeline_ReadOnlyAccess", "arn:aws:iam::aws:policy/AWSCodeBuildReadOnlyAccess"])
  instance_arn       = aws_ssoadmin_permission_set.delivery_pipelines_readonly.instance_arn
  managed_policy_arn = each.key
  permission_set_arn = aws_ssoadmin_permission_set.delivery_pipelines_readonly.arn
}

# Fetches principal id for the group
data "aws_identitystore_group" "che_sre" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.control_tower_che.identity_store_ids)[0]

  filter {
    attribute_path  = "DisplayName"
    attribute_value = "che-test-group"
  }
}

# Fetch the details of the existing Permission set 
data "aws_ssoadmin_permission_set" "che_admin_access" {
  instance_arn = tolist(data.aws_ssoadmin_instances.control_tower_che.arns)[0]
  name         = "Che-PS-AdministratorAccess"
}

# Creates group assignment (attaching groups to individual AWS accounts)
resource "aws_ssoadmin_account_assignment" "infra_shared_dev" {
  for_each           = toset([var.sandbox-che, var.sandbox-che-1])
  instance_arn       = data.aws_ssoadmin_permission_set.che_admin_access.instance_arn
  permission_set_arn = data.aws_ssoadmin_permission_set.che_admin_access.arn

  principal_id   = data.aws_identitystore_group.che_sre.group_id
  principal_type = "GROUP"

  target_id   = each.key
  target_type = "AWS_ACCOUNT"
}