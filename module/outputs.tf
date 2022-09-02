## Fetches each account in our AWS organization
output "aws_organizations_organization" {
  value = data.aws_organizations_organization.org_che.accounts[*].id
}

## Fetches full organization details
output "aws_organizations_organization_full" {
  value = data.aws_organizations_organization.org_che
}

## Outputs SSO INSTANCE Details
output "ssoadmin_instance" {
  value = data.aws_ssoadmin_instances.control_tower_che
}
