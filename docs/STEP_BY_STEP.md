# Step by step

A command checklist. Run everything from the repo root in a Linux shell (WSL2 works).

## 0. Before you start

- Your own AWS account with a $10 budget alert, and AWS CLI credentials (`aws sts get-caller-identity` works)
- Terraform 1.10+, Ansible with `boto3`, `git`, `gh`, `make`
- An SSH key: `ssh-keygen -t ed25519 -f ~/.ssh/fleet_ed25519 -C fleet`

## 1. Put the code on GitHub

```bash
git init -b main && git add . && git commit -m "Initial commit"
gh auth login
gh repo create hardened-rhel-fleet --public --source=. --push
```

## 2. Bootstrap AWS (once)

```bash
cp bootstrap/terraform.tfvars.example bootstrap/terraform.tfvars   # set github_owner
make bootstrap

gh variable set AWS_REGION          --body "$(terraform -chdir=bootstrap output -raw region)"
gh variable set TF_STATE_BUCKET     --body "$(terraform -chdir=bootstrap output -raw state_bucket)"
gh variable set AWS_PLAN_ROLE_ARN   --body "$(terraform -chdir=bootstrap output -raw plan_role_arn)"
gh variable set AWS_DEPLOY_ROLE_ARN --body "$(terraform -chdir=bootstrap output -raw deploy_role_arn)"
gh variable set SSH_PUBLIC_KEY      --body "$(cat ~/.ssh/fleet_ed25519.pub)"
gh secret   set ADMIN_CIDR          --body "$(curl -s https://checkip.amazonaws.com)/32"
```

Then create an environment named `production` in the repo settings and add yourself as a
required reviewer.

## 3. Build the fleet

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars   # set admin_cidr and ssh_public_key
make init
make plan        # Plan: 15 to add
make apply
make inventory   # three hosts in the "fleet" group
make ping
```

## 4. Scan, harden, scan

```bash
make scan-before
make harden          # one server at a time, with a reboot and checks
make scan-after
make score           # paste the table into README.md
make harden-check    # second run: few or no changes
```

Reports are saved in `reports/<server>/` (ignored by Git).

## 5. Show the pipeline

```bash
git checkout -b add-environment-tag
# add  Environment = "lab"  to the tags in terraform/compute.tf
git commit -am "Tag fleet servers with Environment=lab"
git push -u origin add-environment-tag
gh pr create --fill
```

Wait for the four CI jobs and the plan comment, merge, then approve the `production`
deployment in the Actions tab.

## 6. Clean up

```bash
make destroy                          # servers and network
terraform -chdir=bootstrap destroy    # optional: state bucket and IAM roles
```

## If something fails

| Symptom | Fix |
| --- | --- |
| `make ping` times out | Your IP changed: update `admin_cidr`, `make apply`, and the `ADMIN_CIDR` secret |
| No hosts in the inventory | Check region, `boto3`, and AWS credentials |
| `sts:AssumeRoleWithWebIdentity` denied | Environment must be named `production`; owner and repo in bootstrap must match exactly |
| OIDC provider `EntityAlreadyExists` | Set `create_oidc_provider = false` in `bootstrap/terraform.tfvars` |
| A server stops accepting SSH | `terraform -chdir=terraform apply -replace='aws_instance.fleet[0]'` |
