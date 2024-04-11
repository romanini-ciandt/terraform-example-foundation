/**
 * Copyright 2021 Google LLC
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

locals {
  organization_id = local.parent_folder != "" ? null : local.org_id
  folder_id       = local.parent_folder != "" ? local.parent_folder : null
  policy_for      = local.parent_folder != "" ? "folder" : "organization"

  essential_contacts_domains_to_allow = concat(
    [for domain in var.essential_contacts_domains_to_allow : domain if can(regex("^@.*$", domain)) == true],
    [for domain in var.essential_contacts_domains_to_allow : "@${domain}" if can(regex("^@.*$", domain)) == false]
  )

  boolean_type_organization_policies = toset([
    "compute.disableNestedVirtualization",
    "compute.disableSerialPortAccess",
    "compute.skipDefaultNetworkCreation",
    "compute.restrictXpnProjectLienRemoval",
    "compute.disableVpcExternalIpv6",

    #Control ID: DNS-CO-4.1
    #NIST 800-53: AC-3 AC-17 AC-20
    #CRI Profile: PR.AC-3.1 PR.AC-3.2 PR.AC-4.1 PR.AC-4.2 PR.AC-4.3 PR.AC-6.1 PR.PT-3.1 PR.PT-4.1
    "compute.setNewProjectDefaultToZonalDNSOnly",
    "compute.requireOsLogin",
    "sql.restrictPublicIp",
    "sql.restrictAuthorizedNetworks",

    #Control ID: IAM-CO-4.2
    #NIST 800-53: AC-3 AC-17 AC-20
    #CRI Profile: PR.AC-3.1 PR.AC-3.2 PR.AC-4.1 PR.AC-4.2 PR.AC-4.3 PR.AC-6.1 PR.PT-3.1 PR.PT-4.1
    "iam.disableServiceAccountKeyCreation",

    #Control ID: IAM-CO-4.1
    #NIST 800-53: AC-3 AC-17 AC-20
    #CRI Profile: PR.AC-3.1 PR.AC-3.2 PR.AC-4.1 PR.AC-4.2 PR.AC-4.3 PR.AC-6.1 PR.PT-3.1 PR.PT-4.1
    "iam.automaticIamGrantsForDefaultServiceAccounts",

    #Control ID: IAM-CO-4.3
    #NIST 800-53: AC-3 AC-17 AC-20
    #CRI Profile: PR.AC-3.1 PR.AC-3.2 PR.AC-4.1 PR.AC-4.2 PR.AC-4.3 PR.AC-6.1 PR.PT-3.1 PR.PT-4.1
    "iam.disableServiceAccountKeyUpload",
    "storage.uniformBucketLevelAccess",

    #Control ID: GCS-CO-4.1
    #NIST 800-53: AC-3 AC-17 AC-20
    #CRI Profile: PR.AC-3.1 PR.AC-3.2 PR.AC-4.1 PR.AC-4.2 PR.AC-4.3 PR.AC-6.1 PR.PT-3.1 PR.PT-4.1
    "storage.publicAccessPrevention"
  ])

  private_pools = [local.cloud_build_private_worker_pool_id]
}

module "organization_policies_type_boolean" {
  source   = "terraform-google-modules/org-policy/google"
  version  = "~> 5.1"
  for_each = local.boolean_type_organization_policies

  organization_id = local.organization_id
  folder_id       = local.folder_id
  policy_for      = local.policy_for
  policy_type     = "boolean"
  enforce         = "true"
  constraint      = "constraints/${each.value}"
}

/******************************************
  Compute org policies
*******************************************/

module "org_vm_external_ip_access" {
  source  = "terraform-google-modules/org-policy/google"
  version = "~> 5.1"

  organization_id = local.organization_id
  folder_id       = local.folder_id
  policy_for      = local.policy_for
  policy_type     = "list"
  enforce         = "true"
  constraint      = "constraints/compute.vmExternalIpAccess"
}

module "restrict_protocol_fowarding" {
  source  = "terraform-google-modules/org-policy/google"
  version = "~> 5.1"

  organization_id   = local.organization_id
  folder_id         = local.folder_id
  policy_for        = local.policy_for
  policy_type       = "list"
  allow             = ["INTERNAL"]
  allow_list_length = 1
  constraint        = "constraints/compute.restrictProtocolForwardingCreationForTypes"
}

/******************************************
  IAM
*******************************************/

#Control ID: COM-CO-4.1
#NIST 800-53: AC-3 AC-17 AC-20
#CRI Profile: PR.AC-3.1 PR.AC-3.2 PR.AC-4.1 PR.AC-4.2 PR.AC-4.3 PR.AC-6.1 PR.PT-3.1 PR.PT-4.1

module "org_domain_restricted_sharing" {
  source  = "terraform-google-modules/org-policy/google//modules/domain_restricted_sharing"
  version = "~> 5.1"

  organization_id  = local.organization_id
  folder_id        = local.folder_id
  policy_for       = local.policy_for
  domains_to_allow = var.domains_to_allow
}

/******************************************
  Essential Contacts
*******************************************/

module "domain_restricted_contacts" {
  source  = "terraform-google-modules/org-policy/google"
  version = "~> 5.1"

  organization_id   = local.organization_id
  folder_id         = local.folder_id
  policy_for        = local.policy_for
  policy_type       = "list"
  allow_list_length = length(local.essential_contacts_domains_to_allow)
  allow             = local.essential_contacts_domains_to_allow
  constraint        = "constraints/essentialcontacts.allowedContactDomains"
}

/******************************************
  Cloud build
*******************************************/

module "allowed_worker_pools" {
  source  = "terraform-google-modules/org-policy/google"
  version = "~> 5.1"
  count   = var.enforce_allowed_worker_pools && local.cloud_build_private_worker_pool_id != "" ? 1 : 0

  organization_id   = local.organization_id
  folder_id         = local.folder_id
  policy_for        = local.policy_for
  policy_type       = "list"
  allow_list_length = length(local.private_pools)
  allow             = local.private_pools
  constraint        = "constraints/cloudbuild.allowedWorkerPools"
}

/******************************************
  Access Context Manager Policy
*******************************************/

resource "google_access_context_manager_access_policy" "access_policy" {
  count  = var.create_access_context_manager_access_policy ? 1 : 0
  parent = "organizations/${local.org_id}"
  title  = "default policy"
}
