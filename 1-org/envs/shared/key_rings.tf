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


// Create two keyrings in two geographic regions

module "kms_keyrings" {
  for_each = toset(var.keyring_regions)
  source   = "terraform-google-modules/kms/google"
  version  = "~> 2.1"

  project_id      = module.org_kms.project_id
  keyring         = var.keyring_name
  location        = each.key
  prevent_destroy = "false"

  depends_on = [module.org_kms]
}
