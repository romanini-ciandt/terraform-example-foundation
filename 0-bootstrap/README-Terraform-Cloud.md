# Deploying a Terraform Cloud compatible environment

The objective of the instructions below is to configure the infrastructure that allows you to run CI/CD deployments using
Terraform Cloud for the Terraform Example Foundation stages (`0-bootstrap`, `1-org`, `2-environments`, `3-networks`, `4-projects`).
The infrastructure consists in two Google Cloud Platform projects (`prj-b-seed` and `prj-b-cicd-wif-tfc`).

It is a best practice to have two separate projects here (`prj-b-seed` and `prj-b-cicd-wif-tfc`) for separation of concerns.
On one hand, `prj-b-seed` stores terraform state and has the Service Accounts able to create / modify infrastructure.
On the other hand, the authentication infrastructure using [Workload identity federation](https://cloud.google.com/iam/docs/workload-identity-federation) is implemented in `prj-b-cicd-wif-tfc`.

## Requirements

To run the instructions described in this document, install the following:

- [Google Cloud SDK](https://cloud.google.com/sdk/install) version 393.0.0 or later
    - [terraform-tools](https://cloud.google.com/docs/terraform/policy-validation/validate-policies#install) component
- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) version 2.28.0 or later
- [Terraform](https://www.terraform.io/downloads.html) version 1.3.0  or later

Also make sure that you have the following:

- A [Terraform Cloud account](https://developer.hashicorp.com/terraform/tutorials/cloud-get-started/cloud-sign-up#create-an-account) for your User or [Organization](https://developer.hashicorp.com/terraform/tutorials/cloud-get-started/cloud-sign-up#create-an-organization).
- A Terraform Cloud [organization](https://developer.hashicorp.com/terraform/cloud-docs/users-teams-organizations/organizations#creating-organizations).
- A Terraform Cloud [User token](https://developer.hashicorp.com/terraform/cloud-docs/users-teams-organizations/api-tokens#user-api-tokens) or [Organization token](https://developer.hashicorp.com/terraform/cloud-docs/users-teams-organizations/api-tokens#organization-api-tokens).
   - Organization token is prefered since the permissions are limited to a single TFC organization.
- A [supported](https://developer.hashicorp.com/terraform/cloud-docs/vcs#supported-vcs-providers) version control system (VCS) provider [connected](https://developer.hashicorp.com/terraform/cloud-docs/vcs) with your Terraform Cloud account.
   - See [GitHub VCS connection](https://developer.hashicorp.com/terraform/cloud-docs/vcs/github) or [GitLab VCS connection](https://developer.hashicorp.com/terraform/cloud-docs/vcs/gitlab-com) for more details.
- A **private** repository (or project) in your VCS provider for each one of the stages of Foundation:
   - Bootstrap
   - Organization
   - Environments
   - Networks
   - Projects
   - See [GitHub repository creation](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-new-repository) or [GitLab project creation](https://docs.gitlab.com/ee/user/project/index.html#create-a-blank-project) for more details.
- A Google Cloud [organization](https://cloud.google.com/resource-manager/docs/creating-managing-organization).
- A Google Cloud [billing account](https://cloud.google.com/billing/docs/how-to/manage-billing-account).
- Cloud Identity or Google Workspace groups for organization and billing admins.
- Add the Identity (user or Service Account) who will run Terraform to the `group_org_admins` group.
They must be in this group, or they won't have `roles/resourcemanager.projectCreator` access.
- For the Identity who will run the procedures in this document, grant the following roles:
    - The `roles/resourcemanager.organizationAdmin` role on the Google Cloud organization.
    - The `roles/orgpolicy.policyAdmin` role on the Google Cloud organization.
    - The `roles/billing.admin` role on the billing account.
    - The `roles/resourcemanager.folderCreator` role.

If other users need to be able to run these procedures, add them to the group
represented by the `org_project_creators` variable.
For more information about the permissions that are required, and the resources
that are created, see the organization bootstrap module
[documentation.](https://github.com/terraform-google-modules/terraform-google-bootstrap)

### Instructions

1. Clone [terraform-example-foundation](https://github.com/terraform-google-modules/terraform-example-foundation) into your local environment.

   ```bash
   git clone https://github.com/terraform-google-modules/terraform-example-foundation.git
   ```

1. Clone all the private repositories (or projects) you created at the same level of the `terraform-example-foundation` folder.
You must be authenticated to the VCS provider. See [GitHub authentication](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/about-authentication-to-github) or [GitLab authentication](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/about-authentication-to-github) for more details.

   ```bash
   git clone git@<VCS-SERVICE-PROVIDER>.com:<VCS-OWNER>/<VCS-BOOTSTRAP-REPO>.git gcp-bootstrap
   ```
   ```bash
   git clone git@<VCS-SERVICE-PROVIDER>.com:<VCS-OWNER>/<VCS-ORGANIZATION-REPO>.git gcp-org
   ```
   ```bash
   git clone git@<VCS-SERVICE-PROVIDER>.com:<VCS-OWNER>/<VCS-ENVIRONMENTS-REPO>.git gcp-environments
   ```
   ```bash
   git clone git@<VCS-SERVICE-PROVIDER>.com:<VCS-OWNER>/<VCS-NETWORKS-REPO>.git gcp-networks
   ```
   ```bash
   git clone git@<VCS-SERVICE-PROVIDER>.com:<VCS-OWNER>/<VCS-PROJECTS-REPO>.git gcp-projects
   ```

1. The layout should be:

   ```bash
   gcp-bootstrap/
   gcp-org/
   gcp-environments/
   gcp-networks/
   gcp-projects/
   terraform-example-foundation/
   ```

1. In your VCS repositories (or projects) it is expected to have the following branches created. You can either create manually, or run `scripts/git_create_branches_helper.sh` script to automate the process.
   - Bootstrap: `production`
   - Organization: `production`
   - Environments: `development`, `non-production` and `production`
   - Networks: `development`, `non-production` and `production`
   - Projects: `development`, `non-production` and `production`
   - Note: `scripts/git_create_branches_helper.sh` script assume you are running it from the directory that has all the repos cloned (layout described in the previous step). If you run from another directory, adjust the `BASE_PATH` variable at the `scripts/git_create_branches_helper.sh` file.

### Deploying step 0-bootstrap

1. Navigate into the repo. All subsequent
   steps assume you are running them from the `gcp-bootstrap` directory.
   If you run them from another directory, adjust your copy paths accordingly.

   ```bash
   cd gcp-bootstrap
   ```

1. Seed the repository if it has not been initialized yet.

   ```bash
   git commit --allow-empty -m 'repository seed'
   git push --set-upstream origin main

   git checkout -b production
   git push --set-upstream origin production
   ```

1. change to a non-production branch.

   ```bash
   git checkout -b plan
   ```

1. Copy contents of foundation to new repo (modify accordingly based on your current directory).

   ```bash
   mkdir -p envs/shared

   cp -RT ../terraform-example-foundation/0-bootstrap/ ./envs/shared
   cp -RT ../terraform-example-foundation/policy-library/ ./policy-library
   mkdir -p .github/workflows
   cp ../terraform-example-foundation/build/github-tf-* ./.github/workflows/
   cp ../terraform-example-foundation/build/tf-wrapper.sh .
   chmod 755 ./tf-wrapper.sh
   cd ./envs/shared
   ```

1. In the versions file `./versions.tf` un-comment the `github` required provider
1. In the variables file `./variables.tf` un-comment variables in the section `Specific to github_bootstrap`
1. In the outputs file `./outputs.tf` Comment-out outputs in the section `Specific to cloudbuild_module`
1. In the outputs file `./outputs.tf` un-comment outputs in the section `Specific to github_bootstrap`
1. Rename file `./cb.tf` to `./cb.tf.example`

   ```bash
   mv ./cb.tf ./cb.tf.example
   ```

1. Rename file `./github.tf.example` to `./github.tf`

   ```bash
   mv ./github.tf.example ./github.tf
   ```

1. Rename file `terraform.example.tfvars` to `terraform.tfvars`

   ```bash
   mv ./terraform.example.tfvars ./terraform.tfvars
   ```

1. Update the file `terraform.tfvars` with values from your Google Cloud environment
1. Update the file `terraform.tfvars` with values from your GitHub repositories
1. To prevent saving the `gh_token` in plain text in the `terraform.tfvars` file,
export the GitHub fine grained access token as an environment variable:

   ```bash
   export TF_VAR_gh_token="YOUR-FINE-GRAINED-ACCESS-TOKEN"
   ```

1. Use the helper script [validate-requirements.sh](../scripts/validate-requirements.sh) to validate your environment:

   ```bash
   ../../../terraform-example-foundation/scripts/validate-requirements.sh  -o <ORGANIZATION_ID> -b <BILLING_ACCOUNT_ID> -u <END_USER_EMAIL> -t GitHub
   ```

   **Note:** The script is not able to validate if the user is in a Cloud Identity or Google Workspace group with the required roles.

1. Run `terraform init` and `terraform plan` and review the output.

   ```bash
   terraform init
   terraform plan -input=false -out bootstrap.tfplan
   ```

1. To  validate your policies, run `gcloud beta terraform vet`. For installation instructions, see [Validate policies](https://cloud.google.com/docs/terraform/policy-validation/validate-policies) instructions for the Google Cloud CLI.

1. Run the following commands and check for violations:

   ```bash
   export VET_PROJECT_ID=A-VALID-PROJECT-ID

   terraform show -json bootstrap.tfplan > bootstrap.json
   gcloud beta terraform vet bootstrap.json --policy-library="../../policy-library" --project ${VET_PROJECT_ID}
   ```

   *`A-VALID-PROJECT-ID`* must be an existing project you have access to. This is necessary because Terraform-validator needs to link resources to a valid Google Cloud Platform project.

1. No violations and an output with `done` means the validation was successful.

1. Run `terraform apply`.

   ```bash
   terraform apply bootstrap.tfplan
   ```

1. Run `terraform output` to get the email address of the terraform service accounts that will be used to run manual steps for `shared` environments in steps `3-networks-dual-svpc`, `3-networks-hub-and-spoke`, and `4-projects`.

   ```bash
   export network_step_sa=$(terraform output -raw networks_step_terraform_service_account_email)
   export projects_step_sa=$(terraform output -raw projects_step_terraform_service_account_email)

   echo "network step service account = ${network_step_sa}"
   echo "projects step service account = ${projects_step_sa}"
   ```

1. Run `terraform output` to get the ID of your CI/CD project:

   ```bash
   export cicd_project_id=$(terraform output -raw cicd_project_id)
   echo "CI/CD Project ID = ${cicd_project_id}"
   ```

1. Copy the backend and update `backend.tf` with the name of your Google Cloud Storage bucket for Terraform's state. Also update the `backend.tf` of all steps.

   ```bash
   export backend_bucket=$(terraform output -raw gcs_bucket_tfstate)
   echo "backend_bucket = ${backend_bucket}"

   cp backend.tf.example backend.tf
   cd ../../../

   for i in `find -name 'backend.tf'`; do sed -i "s/UPDATE_ME/${backend_bucket}/" $i; done
   for i in `find -name 'backend.tf'`; do sed -i "s/UPDATE_PROJECTS_BACKEND/${backend_bucket}/" $i; done

   cd gcp-bootstrap/envs/shared
   ```

1. Re-run `terraform init`. When you're prompted, agree to copy Terraform state to Cloud Storage.

   ```bash
   terraform init
   ```

1. (Optional) Run `terraform plan` to verify that state is configured correctly. You should see no changes from the previous state.
1. Save the Terraform configuration to `gcp-bootstrap` github repository:

   ```bash
   cd ../..
   git add .
   git commit -m 'Initialize bootstrap repo'
   git push --set-upstream origin plan
   ```

1. Open a pull request in GitHub https://github.com/GITHUB-OWNER/GITHUB-BOOTSTRAP-REPO/pull/new/plan from the `plan` branch to the `production` branch and review the output.
1. The Pull request will trigger a GitHub Action that will run Terraform `init`/`plan`/`validate` in the `production` environment.
1. Review the GitHub Action output in GitHub https://github.com/GITHUB-OWNER/GITHUB-BOOTSTRAP-REPO/actions under `tf-pull-request`.
1. If the GitHub action is successful, merge the pull request in to the `production` branch.
1. The merge will trigger a GitHub Action that will apply the terraform configuration for the `production` environment.
1. Review merge output in GitHub https://github.com/GITHUB-OWNER/GITHUB-BOOTSTRAP-REPO/actions under `tf-apply`.

**Note 1:** The stages after `0-bootstrap` use `terraform_remote_state` data source to read common configuration like the organization ID from the output of the `0-bootstrap` stage.
They will [fail](../docs/TROUBLESHOOTING.md#error-unsupported-attribute) if the state is not copied to the Cloud Storage bucket.

**Note 2:** After the deploy, to prevent the project quota error described in the [Troubleshooting guide](../docs/TROUBLESHOOTING.md#project-quota-exceeded),
we recommend that you request 50 additional projects for the **projects step service account** created in this step.

## Deploying step 1-org

1. Clone the repository you created to host the `1-org` terraform configuration at the same level of the `terraform-example-foundation` folder.

   ```bash
   git clone git@github.com:<GITHUB-OWNER>/<GITHUB-ORGANIZATION-REPO>.git gcp-org
   ```

1. Navigate into the repo. All subsequent steps assume you are running them from the `gcp-org` directory.
   If you run them from another directory, adjust your copy paths accordingly.

   ```bash
   cd gcp-org
   ```

1. Seed the repository if it has not been initialized yet.

   ```bash
   git commit --allow-empty -m 'repository seed'
   git push --set-upstream origin main

   git checkout -b production
   git push --set-upstream origin production
   ```

1. change to a non-production branch.

   ```bash
   git checkout -b plan
   ```

1. Copy contents of foundation to new repo.

   ```bash
   cp -RT ../terraform-example-foundation/1-org/ .
   cp -RT ../terraform-example-foundation/policy-library/ ./policy-library
   mkdir -p .github/workflows
   cp ../terraform-example-foundation/build/github-tf-* ./.github/workflows/
   cp ../terraform-example-foundation/build/tf-wrapper.sh .
   chmod 755 ./tf-wrapper.sh
   ```

1. Rename `./envs/shared/terraform.example.tfvars` to `./envs/shared/terraform.tfvars`

   ```bash
   mv ./envs/shared/terraform.example.tfvars ./envs/shared/terraform.tfvars
   ```

1. Update the file `envs/shared/terraform.tfvars` with values from your GCP environment.
See the shared folder [README.md](../1-org/envs/shared/README.md#inputs) for additional information on the values in the `terraform.tfvars` file.

1. Un-comment the variable `create_access_context_manager_access_policy = false` if your organization already has an Access Context Manager Policy.

    ```bash
    export ORGANIZATION_ID=$(terraform -chdir="../gcp-bootstrap/envs/shared" output -json common_config | jq '.org_id' --raw-output)

    export ACCESS_CONTEXT_MANAGER_ID=$(gcloud access-context-manager policies list --organization ${ORGANIZATION_ID} --format="value(name)")

    echo "access_context_manager_policy_id = ${ACCESS_CONTEXT_MANAGER_ID}"

    if [ ! -z "${ACCESS_CONTEXT_MANAGER_ID}" ]; then sed -i "s=//create_access_context_manager_access_policy=create_access_context_manager_access_policy=" ./envs/shared/terraform.tfvars; fi
    ```

1. Update the `remote_state_bucket` variable with the backend bucket from step Bootstrap.

   ```bash
   export backend_bucket=$(terraform -chdir="../gcp-bootstrap/envs/shared" output -raw gcs_bucket_tfstate)

   echo "remote_state_bucket = ${backend_bucket}"

   sed -i "s/REMOTE_STATE_BUCKET/${backend_bucket}/" ./envs/shared/terraform.tfvars
   ```

1. Check if a Security Command Center Notification with the default name, **scc-notify**, already exists in your organization.

   ```bash
   export ORG_STEP_SA=$(terraform -chdir="../gcp-bootstrap/envs/shared" output -raw organization_step_terraform_service_account_email)

   gcloud scc notifications describe "scc-notify" --format="value(name)" --organization=${ORGANIZATION_ID} --impersonate-service-account=${ORG_STEP_SA}
   ```

1. If the notification exists the output will be:

    ```text
    organizations/ORGANIZATION_ID/notificationConfigs/scc-notify
    ```

1. If the notification does not exist the output will be:

    ```text
    ERROR: (gcloud.scc.notifications.describe) NOT_FOUND: Requested entity was not found.
    ```

1. If the notification exists, choose a different value for the `scc_notification_name` variable in the `./envs/shared/terraform.tfvars` file.

1. Commit changes.

   ```bash
   git add .
   git commit -m 'Initialize org repo'
   ```

1. Push your plan branch.

   ```bash
   git push --set-upstream origin plan
   ```

1. Open a pull request in GitHub https://github.com/GITHUB-OWNER/GITHUB-ORGANIZATION-REPO/pull/new/plan from the `plan` branch to the `production` branch and review the output.
1. The Pull request will trigger a GitHub Action that will run Terraform `init`/`plan`/`validate` in the `production` environment.
1. Review the GitHub Action output in GitHub https://github.com/GITHUB-OWNER/GITHUB-ORGANIZATION-REPO/actions under `tf-pull-request`.
1. If the GitHub action is successful, merge the pull request in to the `production` branch.
1. The merge will trigger a GitHub Action that will apply the terraform configuration for the `production` environment.
1. Review merge output in GitHub https://github.com/GITHUB-OWNER/GITHUB-ORGANIZATION-REPO/actions under `tf-apply`.


## Deploying step 2-environments

1. Clone the repository you created to host the `2-environments` terraform configuration at the same level of the `terraform-example-foundation` folder.

   ```bash
   git clone git@github.com:<GITHUB-OWNER>/<GITHUB-ENVIRONMENTS-REPO>.git gcp-environments
   ```

1. Navigate into the repo. All subsequent
   steps assume you are running them from the `gcp-environments` directory.
   If you run them from another directory, adjust your copy paths accordingly.

   ```bash
   cd gcp-environments
   ```

1. Seed the repository if it has not been initialized yet.

   ```bash
   git commit --allow-empty -m 'repository seed'
   git push --set-upstream origin main

   git checkout -b production
   git push --set-upstream origin production

   git checkout -b non-production
   git push --set-upstream origin non-production

   git checkout -b development
   git push --set-upstream origin development
   ```

1. change to a non-production branch.

   ```bash
   git checkout -b plan
   ```

1. Copy contents of foundation to new repo.

   ```bash
   cp -RT ../terraform-example-foundation/2-environments/ .
   cp -RT ../terraform-example-foundation/policy-library/ ./policy-library
   mkdir -p .github/workflows
   cp ../terraform-example-foundation/build/github-tf-* ./.github/workflows/
   cp ../terraform-example-foundation/build/tf-wrapper.sh .
   chmod 755 ./tf-wrapper.sh
   ```

1. Rename `terraform.example.tfvars` to `terraform.tfvars`.

   ```bash
   mv terraform.example.tfvars terraform.tfvars
   ```

1. Update the file with values from your GCP environment.
See any of the envs folder [README.md](../2-environments/envs/production/README.md#inputs) files for additional information on the values in the `terraform.tfvars` file.

1. Update the `remote_state_bucket` variable with the backend bucket from step Bootstrap.

   ```bash
   export backend_bucket=$(terraform -chdir="../gcp-bootstrap/envs/shared" output -raw gcs_bucket_tfstate)
   echo "remote_state_bucket = ${backend_bucket}"

   sed -i "s/REMOTE_STATE_BUCKET/${backend_bucket}/" terraform.tfvars
   ```

1. Commit changes.

   ```bash
   git add .
   git commit -m 'Initialize environments repo'
   ```

1. Push your plan branch.

   ```bash
   git push --set-upstream origin plan
   ```

1. Open a pull request in GitHub https://github.com/GITHUB-OWNER/GITHUB-ENVIRONMENTS-REPO/pull/new/plan from the `plan` branch to the `development` branch and review the output.
1. The Pull request will trigger a GitHub Action that will run Terraform `init`/`plan`/`validate` in the `development` environment.
1. Review the GitHub Action output in GitHub https://github.com/GITHUB-OWNER/GITHUB-ENVIRONMENTS-REPO/actions under `tf-pull-request`.
1. If the GitHub action is successful, merge the pull request in to the `development` branch.
1. The merge will trigger a GitHub Action that will apply the terraform configuration for the `development` environment.
1. Review merge output in GitHub https://github.com/GITHUB-OWNER/GITHUB-ENVIRONMENTS-REPO/actions under `tf-apply`.
1. If the GitHub action is successful, apply the next environment.

1. Open a pull request in GitHub https://github.com/GITHUB-OWNER/GITHUB-ENVIRONMENTS-REPO/pull/new/development from the `development` branch to the `non-production` branch and review the output.
1. The Pull request will trigger a GitHub Action that will run Terraform `init`/`plan`/`validate` in the `non-production` environment.
1. Review the GitHub Action output in GitHub https://github.com/GITHUB-OWNER/GITHUB-ENVIRONMENTS-REPO/actions under `tf-pull-request`.
1. If the GitHub action is successful, merge the pull request in to the `non-production` branch.
1. The merge will trigger a GitHub Action that will apply the terraform configuration for the `non-production` environment.
1. Review merge output in GitHub https://github.com/GITHUB-OWNER/GITHUB-ENVIRONMENTS-REPO/actions under `tf-apply`.
1. If the GitHub action is successful, apply the next environment.

1. Open a pull request in GitHub https://github.com/GITHUB-OWNER/GITHUB-ENVIRONMENTS-REPO/pull/new/non-production from the `non-production` branch to the `production` branch and review the output.
1. The Pull request will trigger a GitHub Action that will run Terraform `init`/`plan`/`validate` in the `production` environment.
1. Review the GitHub Action output in GitHub https://github.com/GITHUB-OWNER/GITHUB-ENVIRONMENTS-REPO/actions under `tf-pull-request`.
1. If the GitHub action is successful, merge the pull request in to the `production` branch.
1. The merge will trigger a GitHub Action that will apply the terraform configuration for the `production` environment.
1. Review merge output in GitHub https://github.com/GITHUB-OWNER/GITHUB-ENVIRONMENTS-REPO/actions under `tf-apply`.

1. You can now move to the instructions in the network stage.
To use the [Dual Shared VPC](https://cloud.google.com/architecture/security-foundations/networking#vpcsharedvpc-id7-1-shared-vpc-) network mode go to [Deploying step 3-networks-dual-svpc](#deploying-step-3-networks-dual-svpc),
or go to [Deploying step 3-networks-hub-and-spoke](#deploying-step-3-networks-hub-and-spoke) to use the [Hub and Spoke](https://cloud.google.com/architecture/security-foundations/networking#hub-and-spoke) network mode.

## Deploying step 3-networks-dual-svpc

1. Clone the repository you created to host the `3-networks-dual-svpc` terraform configuration at the same level of the `terraform-example-foundation` folder.

   ```bash
   git clone git@github.com:<GITHUB-OWNER>/<GITHUB-NETWORKS-REPO>.git gcp-networks
   ```

1. Navigate into the repo. All subsequent steps assume you are running them from the `gcp-networks` directory.
   If you run them from another directory, adjust your copy paths accordingly.

   ```bash
   cd gcp-networks
   ```

1. Seed the repository if it has not been initialized yet.

   ```bash
   git commit --allow-empty -m 'repository seed'
   git push --set-upstream origin main

   git checkout -b production
   git push --set-upstream origin production

   git checkout -b non-production
   git push --set-upstream origin non-production

   git checkout -b development
   git push --set-upstream origin development
   ```

1. change to a non-production branch.

   ```bash
   git checkout -b plan
   ```

1. Copy contents of foundation to new repo.

   ```bash
   cp -RT ../terraform-example-foundation/3-networks-dual-svpc/ .
   cp -RT ../terraform-example-foundation/policy-library/ ./policy-library
   mkdir -p .github/workflows
   cp ../terraform-example-foundation/build/github-tf-* ./.github/workflows/
   cp ../terraform-example-foundation/build/tf-wrapper.sh .
   chmod 755 ./tf-wrapper.sh
   ```

1. Rename `common.auto.example.tfvars` to `common.auto.tfvars`, rename `shared.auto.example.tfvars` to `shared.auto.tfvars` and rename `access_context.auto.example.tfvars` to `access_context.auto.tfvars`.

   ```bash
   mv common.auto.example.tfvars common.auto.tfvars
   mv shared.auto.example.tfvars shared.auto.tfvars
   mv access_context.auto.example.tfvars access_context.auto.tfvars
   ```

1. Update the file `shared.auto.tfvars` with the values for the `target_name_server_addresses`.
1. Update the file `access_context.auto.tfvars` with the organization's `access_context_manager_policy_id`.

   ```bash
   export ORGANIZATION_ID=$(terraform -chdir="../gcp-bootstrap/envs/shared/" output -json common_config | jq '.org_id' --raw-output)

   export ACCESS_CONTEXT_MANAGER_ID=$(gcloud access-context-manager policies list --organization ${ORGANIZATION_ID} --format="value(name)")

   echo "access_context_manager_policy_id = ${ACCESS_CONTEXT_MANAGER_ID}"

   sed -i "s/ACCESS_CONTEXT_MANAGER_ID/${ACCESS_CONTEXT_MANAGER_ID}/" ./access_context.auto.tfvars
   ```

1. Update `common.auto.tfvars` file with values from your GCP environment.
See any of the envs folder [README.md](../3-networks-dual-svpc/envs/production/README.md#inputs) files for additional information on the values in the `common.auto.tfvars` file.
1. You must add your user email in the variable `perimeter_additional_members` to be able to see the resources created in the restricted project.
1. Update the `remote_state_bucket` variable with the backend bucket from step Bootstrap in the `common.auto.tfvars` file.

   ```bash
   export backend_bucket=$(terraform -chdir="../gcp-bootstrap/envs/shared/" output -raw gcs_bucket_tfstate)

   echo "remote_state_bucket = ${backend_bucket}"

   sed -i "s/REMOTE_STATE_BUCKET/${backend_bucket}/" ./common.auto.tfvars
   ```

1. Commit changes

   ```bash
   git add .
   git commit -m 'Initialize networks repo'
   ```

1. You must manually plan and apply the `shared` environment (only once) since the `development`, `non-production` and `production` environments depend on it.
1. Use `terraform output` to get the CI/CD project ID and the networks step Terraform Service Account from gcp-bootstrap output.
1. The CI/CD project ID will be used in the [validation](https://cloud.google.com/docs/terraform/policy-validation/quickstart) of the Terraform configuration

   ```bash
   export CICD_PROJECT_ID=$(terraform -chdir="../gcp-bootstrap/envs/shared/" output -raw cicd_project_id)
   echo ${CICD_PROJECT_ID}
   ```

1. The networks step Terraform Service Account will be used for [Service Account impersonation](https://cloud.google.com/docs/authentication/use-service-account-impersonation) in the following steps.
An environment variable `GOOGLE_IMPERSONATE_SERVICE_ACCOUNT` will be set with the Terraform Service Account to enable impersonation.

   ```bash
   export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=$(terraform -chdir="../gcp-bootstrap/envs/shared/" output -raw networks_step_terraform_service_account_email)
   echo ${GOOGLE_IMPERSONATE_SERVICE_ACCOUNT}
   ```

1. Run `init` and `plan` and review output for environment shared.

   ```bash
   ./tf-wrapper.sh init shared
   ./tf-wrapper.sh plan shared
   ```

1. To use the `validate` option of the `tf-wrapper.sh` script, please follow the [instructions](https://cloud.google.com/docs/terraform/policy-validation/validate-policies#install) to install the terraform-tools component.
1. Run `validate` and check for violations.

   ```bash
   ./tf-wrapper.sh validate shared $(pwd)/policy-library ${CICD_PROJECT_ID}
   ```

1. Run `apply` shared.

   ```bash
   ./tf-wrapper.sh apply shared
   ```

1. Push your plan branch.

   ```bash
   git push --set-upstream origin plan
   ```

1. Open a pull request in GitHub https://github.com/GITHUB-OWNER/GITHUB-NETWORKS-REPO/pull/new/plan from the `plan` branch to the `development` branch and review the output.
1. The Pull request will trigger a GitHub Action that will run Terraform `init`/`plan`/`validate` in the `development` environment.
1. Review the GitHub Action output in GitHub https://github.com/GITHUB-OWNER/GITHUB-NETWORKS-REPO/actions under `tf-pull-request`.
1. If the GitHub action is successful, merge the pull request in to the `development` branch.
1. The merge will trigger a GitHub Action that will apply the terraform configuration for the `development` environment.
1. Review merge output in GitHub https://github.com/GITHUB-OWNER/GITHUB-NETWORKS-REPO/actions under `tf-apply`.
1. If the GitHub action is successful, apply the next environment.

1. Open a pull request in GitHub https://github.com/GITHUB-OWNER/GITHUB-NETWORKS-REPO/pull/new/development from the `development` branch to the `non-production` branch and review the output.
1. The Pull request will trigger a GitHub Action that will run Terraform `init`/`plan`/`validate` in the `non-production` environment.
1. Review the GitHub Action output in GitHub https://github.com/GITHUB-OWNER/GITHUB-NETWORKS-REPO/actions under `tf-pull-request`.
1. If the GitHub action is successful, merge the pull request in to the `non-production` branch.
1. The merge will trigger a GitHub Action that will apply the terraform configuration for the `non-production` environment.
1. Review merge output in GitHub https://github.com/GITHUB-OWNER/GITHUB-NETWORKS-REPO/actions under `tf-apply`.
1. If the GitHub action is successful, apply the next environment.

1. Open a pull request in GitHub https://github.com/GITHUB-OWNER/GITHUB-NETWORKS-REPO/pull/new/non-production from the `non-production` branch to the `production` branch and review the output.
1. The Pull request will trigger a GitHub Action that will run Terraform `init`/`plan`/`validate` in the `production` environment.
1. Review the GitHub Action output in GitHub https://github.com/GITHUB-OWNER/GITHUB-NETWORKS-REPO/actions under `tf-pull-request`.
1. If the GitHub action is successful, merge the pull request in to the `production` branch.
1. The merge will trigger a GitHub Action that will apply the terraform configuration for the `production` environment.
1. Review merge output in GitHub https://github.com/GITHUB-OWNER/GITHUB-NETWORKS-REPO/actions under `tf-apply`.

1. Before executing the next steps, unset the `GOOGLE_IMPERSONATE_SERVICE_ACCOUNT` environment variable.

   ```bash
   unset GOOGLE_IMPERSONATE_SERVICE_ACCOUNT
   ```

1. You can now move to the instructions in the [4-projects](#deploying-step-4-projects) stage.

## Deploying step 3-networks-hub-and-spoke

1. Clone the repository you created to host the `3-networks-hub-and-spoke` terraform configuration at the same level of the `terraform-example-foundation` folder.

   ```bash
   git clone git@github.com:<GITHUB-OWNER>/<GITHUB-NETWORKS-REPO>.git gcp-networks
   ```

1. Navigate into the repo. All subsequent steps assume you are running them from the `gcp-networks` directory.
   If you run them from another directory, adjust your copy paths accordingly.

   ```bash
   cd gcp-networks
   ```

1. Seed the repository if it has not been initialized yet.

   ```bash
   git commit --allow-empty -m 'repository seed'
   git push --set-upstream origin main

   git checkout -b production
   git push --set-upstream origin production

   git checkout -b non-production
   git push --set-upstream origin non-production

   git checkout -b development
   git push --set-upstream origin development
   ```

1. change to a non-production branch.

   ```bash
   git checkout -b plan
   ```

1. Copy contents of foundation to new repo.

   ```bash
   cp -RT ../terraform-example-foundation/3-networks-hub-and-spoke/ .
   cp -RT ../terraform-example-foundation/policy-library/ ./policy-library
   mkdir -p .github/workflows
   cp ../terraform-example-foundation/build/github-tf-* ./.github/workflows/
   cp ../terraform-example-foundation/build/tf-wrapper.sh .
   chmod 755 ./tf-wrapper.sh
   ```

1. Rename `common.auto.example.tfvars` to `common.auto.tfvars`, rename `shared.auto.example.tfvars` to `shared.auto.tfvars` and rename `access_context.auto.example.tfvars` to `access_context.auto.tfvars`.

   ```bash
   mv common.auto.example.tfvars common.auto.tfvars
   mv shared.auto.example.tfvars shared.auto.tfvars
   mv access_context.auto.example.tfvars access_context.auto.tfvars
   ```

1. Update `common.auto.tfvars` file with values from your GCP environment.
See any of the envs folder [README.md](../3-networks-hub-and-spoke/envs/production/README.md#inputs) files for additional information on the values in the `common.auto.tfvars` file.
1. You must add your user email in the variable `perimeter_additional_members` to be able to see the resources created in the restricted project.
1. Update the `remote_state_bucket` variable with the backend bucket from step Bootstrap in the `common.auto.tfvars` file.

   ```bash
   export backend_bucket=$(terraform -chdir="../gcp-bootstrap/envs/shared/" output -raw gcs_bucket_tfstate)

   echo "remote_state_bucket = ${backend_bucket}"

   sed -i "s/REMOTE_STATE_BUCKET/${backend_bucket}/" ./common.auto.tfvars
   ```

1. Commit changes

   ```bash
   git add .
   git commit -m 'Initialize networks repo'
   ```

1. You must manually plan and apply the `shared` environment (only once) since the `development`, `non-production` and `production` environments depend on it.
1. Use `terraform output` to get the CI/CD project ID and the networks step Terraform Service Account from gcp-bootstrap output.
1. The CI/CD project ID will be used in the [validation](https://cloud.google.com/docs/terraform/policy-validation/quickstart) of the Terraform configuration

   ```bash
   export CICD_PROJECT_ID=$(terraform -chdir="../gcp-bootstrap/envs/shared/" output -raw cicd_project_id)
   echo ${CICD_PROJECT_ID}
   ```

1. The networks step Terraform Service Account will be used for [Service Account impersonation](https://cloud.google.com/docs/authentication/use-service-account-impersonation) in the following steps.
An environment variable `GOOGLE_IMPERSONATE_SERVICE_ACCOUNT` will be set with the Terraform Service Account to enable impersonation.

   ```bash
   export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=$(terraform -chdir="../gcp-bootstrap/envs/shared/" output -raw networks_step_terraform_service_account_email)
   echo ${GOOGLE_IMPERSONATE_SERVICE_ACCOUNT}
   ```

1. Run `init` and `plan` and review output for environment shared.

   ```bash
   ./tf-wrapper.sh init shared
   ./tf-wrapper.sh plan shared
   ```

1. To use the `validate` option of the `tf-wrapper.sh` script, please follow the [instructions](https://cloud.google.com/docs/terraform/policy-validation/validate-policies#install) to install the terraform-tools component.
1. Run `validate` and check for violations.

   ```bash
   ./tf-wrapper.sh validate shared $(pwd)/policy-library ${CICD_PROJECT_ID}
   ```

1. Run `apply` shared.

   ```bash
   ./tf-wrapper.sh apply shared
   ```

1. Push your plan branch.

   ```bash
   git push --set-upstream origin plan
   ```

1. Open a pull request in GitHub https://github.com/GITHUB-OWNER/GITHUB-NETWORKS-REPO/pull/new/plan from the `plan` branch to the `development` branch and review the output.
1. The Pull request will trigger a GitHub Action that will run Terraform `init`/`plan`/`validate` in the `development` environment.
1. Review the GitHub Action output in GitHub https://github.com/GITHUB-OWNER/GITHUB-NETWORKS-REPO/actions under `tf-pull-request`.
1. If the GitHub action is successful, merge the pull request in to the `development` branch.
1. The merge will trigger a GitHub Action that will apply the terraform configuration for the `development` environment.
1. Review merge output in GitHub https://github.com/GITHUB-OWNER/GITHUB-NETWORKS-REPO/actions under `tf-apply`.
1. If the GitHub action is successful, apply the next environment.

1. Open a pull request in GitHub https://github.com/GITHUB-OWNER/GITHUB-NETWORKS-REPO/pull/new/development from the `development` branch to the `non-production` branch and review the output.
1. The Pull request will trigger a GitHub Action that will run Terraform `init`/`plan`/`validate` in the `non-production` environment.
1. Review the GitHub Action output in GitHub https://github.com/GITHUB-OWNER/GITHUB-NETWORKS-REPO/actions under `tf-pull-request`.
1. If the GitHub action is successful, merge the pull request in to the `non-production` branch.
1. The merge will trigger a GitHub Action that will apply the terraform configuration for the `non-production` environment.
1. Review merge output in GitHub https://github.com/GITHUB-OWNER/GITHUB-NETWORKS-REPO/actions under `tf-apply`.
1. If the GitHub action is successful, apply the next environment.

1. Open a pull request in GitHub https://github.com/GITHUB-OWNER/GITHUB-NETWORKS-REPO/pull/new/non-production from the `non-production` branch to the `production` branch and review the output.
1. The Pull request will trigger a GitHub Action that will run Terraform `init`/`plan`/`validate` in the `production` environment.
1. Review the GitHub Action output in GitHub https://github.com/GITHUB-OWNER/GITHUB-NETWORKS-REPO/actions under `tf-pull-request`.
1. If the GitHub action is successful, merge the pull request in to the `production` branch.
1. The merge will trigger a GitHub Action that will apply the terraform configuration for the `production` environment.
1. Review merge output in GitHub https://github.com/GITHUB-OWNER/GITHUB-NETWORKS-REPO/actions under `tf-apply`.


1. Before executing the next steps, unset the `GOOGLE_IMPERSONATE_SERVICE_ACCOUNT` environment variable.

   ```bash
   unset GOOGLE_IMPERSONATE_SERVICE_ACCOUNT
   ```

1. You can now move to the instructions in the [4-projects](#deploying-step-4-projects) stage.

## Deploying step 4-projects

1. Clone the repository you created to host the `4-projects` terraform configuration at the same level of the `terraform-example-foundation` folder.

   ```bash
   git clone git@github.com:<GITHUB-OWNER>/<GITHUB-PROJECTS-REPO>.git gcp-projects
   ```

1. Navigate into the repo. All subsequent
   steps assume you are running them from the `gcp-projects` directory.
   If you run them from another directory, adjust your copy paths accordingly.

   ```bash
   cd gcp-projects
   ```

1. Seed the repository if it has not been initialized yet.

   ```bash
   git commit --allow-empty -m 'repository seed'
   git push --set-upstream origin main

   git checkout -b production
   git push --set-upstream origin production

   git checkout -b non-production
   git push --set-upstream origin non-production

   git checkout -b development
   git push --set-upstream origin development
   ```

1. change to a non-production branch.

   ```bash
   git checkout -b plan
   ```

1. Copy contents of foundation to new repo.

   ```bash
   cp -RT ../terraform-example-foundation/4-projects/ .
   cp -RT ../terraform-example-foundation/policy-library/ ./policy-library
   mkdir -p .github/workflows
   cp ../terraform-example-foundation/build/github-tf-* ./.github/workflows/
   cp ../terraform-example-foundation/build/tf-wrapper.sh .
   chmod 755 ./tf-wrapper.sh
   ```

1. Rename `auto.example.tfvars` files to `auto.tfvars`.

   ```bash
   mv common.auto.example.tfvars common.auto.tfvars
   mv shared.auto.example.tfvars shared.auto.tfvars
   mv development.auto.example.tfvars development.auto.tfvars
   mv non-production.auto.example.tfvars non-production.auto.tfvars
   mv production.auto.example.tfvars production.auto.tfvars
   ```

1. See any of the envs folder [README.md](../4-projects/business_unit_1/production/README.md#inputs) files for additional information on the values in the `common.auto.tfvars`, `development.auto.tfvars`, `non-production.auto.tfvars`, and `production.auto.tfvars` files.
1. See any of the shared folder [README.md](../4-projects/business_unit_1/shared/README.md#inputs) files for additional information on the values in the `shared.auto.tfvars` file.

1. Use `terraform output` to get the backend bucket value from bootstrap output.

   ```bash
   export remote_state_bucket=$(terraform -chdir="../gcp-bootstrap/envs/shared/" output -raw gcs_bucket_tfstate)
   echo "remote_state_bucket = ${remote_state_bucket}"

   sed -i "s/REMOTE_STATE_BUCKET/${remote_state_bucket}/" ./common.auto.tfvars
   ```

1. Commit changes.

   ```bash
   git add .
   git commit -m 'Initialize projects repo'
   ```

1. You need to manually plan and apply only once the `business_unit_1/shared` and `business_unit_2/shared` environments since `development`, `non-production`, and `production` depend on them.

1. Use `terraform output` to get the CI/CD project ID and the projects step Terraform Service Account from gcp-bootstrap output.
1. The CI/CD project ID will be used in the [validation](https://cloud.google.com/docs/terraform/policy-validation/quickstart) of the Terraform configuration

   ```bash
   export CICD_PROJECT_ID=$(terraform -chdir="../gcp-bootstrap/envs/shared/" output -raw cicd_project_id)
   echo ${CICD_PROJECT_ID}
   ```

1. The projects step Terraform Service Account will be used for [Service Account impersonation](https://cloud.google.com/docs/authentication/use-service-account-impersonation) in the following steps.
An environment variable `GOOGLE_IMPERSONATE_SERVICE_ACCOUNT` will be set with the Terraform Service Account to enable impersonation.

   ```bash
   export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=$(terraform -chdir="../gcp-bootstrap/envs/shared/" output -raw projects_step_terraform_service_account_email)
   echo ${GOOGLE_IMPERSONATE_SERVICE_ACCOUNT}
   ```

1. Run `init` and `plan` and review output for environment shared.

   ```bash
   ./tf-wrapper.sh init shared
   ./tf-wrapper.sh plan shared
   ```

1. To use the `validate` option of the `tf-wrapper.sh` script, please follow the [instructions](https://cloud.google.com/docs/terraform/policy-validation/validate-policies#install) to install the terraform-tools component.
1. Run `validate` and check for violations.

   ```bash
   ./tf-wrapper.sh validate shared $(pwd)/policy-library ${CICD_PROJECT_ID}
   ```

1. Run `apply` shared.

   ```bash
   ./tf-wrapper.sh apply shared
   ```

1. Push your plan branch.

   ```bash
   git push --set-upstream origin plan
   ```

1. Open a pull request in GitHub https://github.com/GITHUB-OWNER/GITHUB-PROJECTS-REPO/pull/new/plan from the `plan` branch to the `development` branch and review the output.
1. The Pull request will trigger a GitHub Action that will run Terraform `init`/`plan`/`validate` in the `development` environment.
1. Review the GitHub Action output in GitHub https://github.com/GITHUB-OWNER/GITHUB-PROJECTS-REPO/actions under `tf-pull-request`.
1. If the GitHub action is successful, merge the pull request in to the `development` branch.
1. The merge will trigger a GitHub Action that will apply the terraform configuration for the `development` environment.
1. Review merge output in GitHub https://github.com/GITHUB-OWNER/GITHUB-PROJECTS-REPO/actions under `tf-apply`.
1. If the GitHub action is successful, apply the next environment.

1. Open a pull request in GitHub https://github.com/GITHUB-OWNER/GITHUB-PROJECTS-REPO/pull/new/development from the `development` branch to the `non-production` branch and review the output.
1. The Pull request will trigger a GitHub Action that will run Terraform `init`/`plan`/`validate` in the `non-production` environment.
1. Review the GitHub Action output in GitHub https://github.com/GITHUB-OWNER/GITHUB-PROJECTS-REPO/actions under `tf-pull-request`.
1. If the GitHub action is successful, merge the pull request in to the `non-production` branch.
1. The merge will trigger a GitHub Action that will apply the terraform configuration for the `non-production` environment.
1. Review merge output in GitHub https://github.com/GITHUB-OWNER/GITHUB-PROJECTS-REPO/actions under `tf-apply`.
1. If the GitHub action is successful, apply the next environment.

1. Open a pull request in GitHub https://github.com/GITHUB-OWNER/GITHUB-PROJECTS-REPO/pull/new/non-production from the `non-production` branch to the `production` branch and review the output.
1. The Pull request will trigger a GitHub Action that will run Terraform `init`/`plan`/`validate` in the `production` environment.
1. Review the GitHub Action output in GitHub https://github.com/GITHUB-OWNER/GITHUB-PROJECTS-REPO/actions under `tf-pull-request`.
1. If the GitHub action is successful, merge the pull request in to the `production` branch.
1. The merge will trigger a GitHub Action that will apply the terraform configuration for the `production` environment.
1. Review merge output in GitHub https://github.com/GITHUB-OWNER/GITHUB-PROJECTS-REPO/actions under `tf-apply`.

1. Unset the `GOOGLE_IMPERSONATE_SERVICE_ACCOUNT` environment variable.

   ```bash
   unset GOOGLE_IMPERSONATE_SERVICE_ACCOUNT
   ```