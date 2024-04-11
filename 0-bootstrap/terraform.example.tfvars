/**
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

org_id = "REPLACE_ME" # format "000000000000"

billing_account = "REPLACE_ME" # format "000000-000000-000000"

group_org_admins = "REPLACE_ME"

group_billing_admins = "REPLACE_ME"

# Example of values for the groups
# group_org_admins = "gcp-organization-admins@example.com"
# group_billing_admins = "gcp-billing-admins@example.com"

default_region = "us-central1"

# Optional - for an organization with existing projects or for development/validation.
# Uncomment this variable to place all the example foundation resources under
# the provided folder instead of the root organization.
# The variable value is the numeric folder ID
# The folder must already exist.
# parent_folder = "01234567890"

#  Optional - for enabling the automatic groups creation, uncoment the groups
#  variable and update the values with the desired group names
# groups = {
#   create_groups = true,
#   billing_project = "billing-project",
#   required_groups = {
# group_org_admins           = "group_org_admins_local_test@example.com"
# group_billing_admins       = "group_billing_admins_local_test@example.com"
# billing_data_users         = "billing_data_users_local_test@example.com"
# audit_data_users           = "audit_data_users_local_test@example.com"
# monitoring_workspace_users = "monitoring_workspace_users_local_test@example.com"
#   },
#   optional_groups = {
# gcp_platform_viewer      = "gcp_platform_viewer_local_test@example.com"
# gcp_security_reviewer    = "gcp_security_reviewer_local_test@example.com"
# gcp_network_viewer       = "gcp_network_viewer_local_test@example.com"
# gcp_scc_admin            = "gcp_scc_admin_local_test@example.com"
# gcp_global_secrets_admin = "gcp_global_secrets_admin_local_test@example.com"
# gcp_audit_viewer         = "gcp_audit_viewer_local_test@example.com"
#   }
# }
#


/* ----------------------------------------
    Specific to github_bootstrap
   ---------------------------------------- */
#  Un-comment github_bootstrap and its outputs if you want to use GitHub Actions instead of Cloud Build
# gh_repos = {
#     owner        = "YOUR-GITHUB-USER-OR-ORGANIZATION",
#     bootstrap    = "YOUR-BOOTSTRAP-REPOSITORY",
#     organization = "YOUR-ORGANIZATION-REPOSITORY",
#     environments = "YOUR-ENVIRONMENTS-REPOSITORY",
#     networks     = "YOUR-NETWORKS-REPOSITORY",
#     projects     = "YOUR-PROJECTS-REPOSITORY",
# }
#
#  to prevent saving the `gh_token` in plain text in this file,
#  export the GitHub fine grained access token in the command line
#  as an environment variable before running terraform.
#  Run the following commnad in your shell:
#   export TF_VAR_gh_token="YOUR-FINE-GRAINED-ACCESS-TOKEN"


/* ----------------------------------------
    Specific to jenkins_bootstrap module
   ---------------------------------------- */
#  Un-comment the jenkins_bootstrap module and its outputs if you want to use Jenkins instead of Cloud Build
# jenkins_agent_gce_subnetwork_cidr_range = "172.16.1.0/24"
#
# jenkins_agent_gce_private_ip_address = "172.16.1.6"
#
# jenkins_agent_gce_ssh_pub_key = "ssh-rsa [KEY_VALUE] [USERNAME]"
#
# jenkins_agent_sa_email = "jenkins-agent-gce" # service_account_prefix will be added
#
# jenkins_controller_subnetwork_cidr_range = ["10.1.0.6/32"]
#
# nat_bgp_asn = "64514"
#
# vpn_shared_secret = "shared_secret"
#
# on_prem_vpn_public_ip_address = ""
#
# on_prem_vpn_public_ip_address2 = ""
#
# router_asn = "64515"
#
# bgp_peer_asn = "64513"
#
# tunnel0_bgp_peer_address = "169.254.1.1"
#
# tunnel0_bgp_session_range = "169.254.1.2/30"
#
# tunnel1_bgp_peer_address = "169.254.2.1"
#
# tunnel1_bgp_session_range = "169.254.2.2/30"

/* ----------------------------------------
    Specific to tfc_bootstrap
   ---------------------------------------- */
//  Un-comment tfc_bootstrap and its outputs if you want to use Terraform Cloud instead of Cloud Build
// Format expected: REPO-OWNER/REPO-NAME
#  vcs_repos = {
#    owner        = "YOUR-VCS-USER-OR-ORGANIZATION",
#    bootstrap    = "YOUR-BOOTSTRAP-REPOSITORY",
#    organization = "YOUR-ORGANIZATION-REPOSITORY",
#    environments = "YOUR-ENVIRONMENTS-REPOSITORY",
#    networks     = "YOUR-NETWORKS-REPOSITORY",
#    projects     = "YOUR-PROJECTS-REPOSITORY",
#  }
#  tfc_org_name = "REPLACE_ME"


// Set this to true if you want to use Terraform Cloud Agents instead of Terraform Cloud remote runner
// If true, a private Autopilot GKE cluster will be created in your GCP account to be used as Terraform Cloud Agents
// More info about Agents on: https://developer.hashicorp.com/terraform/cloud-docs/agents

# enable_tfc_cloud_agents = false

//  to prevent saving the `tfc_token` in plain text in this file,
//  export the Terraform Cloud token in the command line
//  as an environment variable before running terraform.
//  Run the following commnad in your shell:
//   export TF_VAR_tfc_token="YOUR-TFC-TOKEN"

//  For VCS connection based in OAuth: (GitHub OAuth/GitHub Enterprise/Gitlab.com/GitLab Enterprise or Community Edition)
//  to prevent saving the `vcs_oauth_token_id` in plain text in this file,
//  export the Terraform Cloud VCS Connection OAuth token ID in the command line
//  as an environment variable before running terraform.

// Note: you should be able to copy `OAuth Token ID` (vcs_oauth_token_id) in TFC console:
// https://app.terraform.io/app/YOUR-TFC-ORGANIZATION/settings/version-control

//  Run the following commnad in your shell:
//   export TF_VAR_vcs_oauth_token_id="YOUR-VCS-OAUTH-TOKEN-ID"

//  For GitHub OAuth see: https://developer.hashicorp.com/terraform/cloud-docs/vcs/github
//  For GitHub Enterprise see: https://developer.hashicorp.com/terraform/cloud-docs/vcs/github-enterprise
//  For GitLab.com see: https://developer.hashicorp.com/terraform/cloud-docs/vcs/gitlab-com
//  For GitLab EE/CE see: https://developer.hashicorp.com/terraform/cloud-docs/vcs/gitlab-eece
