# adel-aws-githubactions-cicd-static-site

A small **production-style** (but beginner-friendly) project to practice **CI/CD with GitHub Actions + Terraform + AWS**.

It deploys a secure static website to AWS using:
- **Terraform** for infrastructure (S3 + CloudFront with Origin Access Control)
- **GitHub Actions** for CI (fmt/validate/plan) and CD (apply + deploy web assets)
- **AWS IAM OIDC** (no long‑lived AWS keys in GitHub)

The website displays a simple status page like:
> **Adel’s deployments are live — GitHub Actions CI/CD succeeded ✅**

> Designed to be **low-cost** and easy to explain in interviews. You should still **destroy** resources when done.

---

## What you’ll practice (interview-friendly)

- GitHub Actions workflows for **plan/apply/destroy**
- Secure AWS auth from GitHub using **OIDC**
- Terraform modules + environment folder (production-style layout)
- S3 + CloudFront **private bucket** (no public S3 access)
- Simple deploy step (upload `dist/` to S3)

---

## Repository structure

```
.
├─ app/                        # simple website source
├─ dist/                       # build output (generated)
├─ infra/
│  ├─ bootstrap/               # creates TF remote state + IAM OIDC role for GitHub
│  ├─ production/              # production environment (calls module)
│  └─ modules/static_site/     # reusable module (S3 + CloudFront)
└─ .github/workflows/          # CI/CD workflows
```

---

## Quick start (safe steps)

### 1) Prereqs (local)
- AWS account (Free Tier is fine)
- AWS CLI configured locally (for bootstrap only)
- Terraform installed
- A GitHub repo created from this project

### 2) Bootstrap (one-time)
This creates:
- an S3 bucket + DynamoDB table for Terraform remote state
- an IAM Role that GitHub Actions can assume using OIDC

```bash
cd infra/bootstrap
terraform init
terraform apply
```

After apply, note the outputs:
- `tf_state_bucket`
- `tf_lock_table`
- `github_actions_role_arn`

### 3) Configure GitHub repository secrets
In your GitHub repo: **Settings → Secrets and variables → Actions → New repository secret**
Add:

- `AWS_REGION` (example: `eu-central-1`)
- `AWS_ROLE_ARN` (from bootstrap output)
- `TF_STATE_BUCKET` (from bootstrap output)
- `TF_LOCK_TABLE` (from bootstrap output)

### 4) Deploy (GitHub Actions)
- Open the **Actions** tab
- Run workflow **Apply (Production)** (manual `workflow_dispatch`)
- Then run workflow **Deploy Website**

You’ll get a CloudFront URL as a Terraform output:
- `site_url` (example: `https://dxxxxxxxxxxxxx.cloudfront.net`)

---

## Cost notes (important)
This project is designed to be **minimal**:
- No EC2
- No NAT Gateway
- No RDS

You may still see small charges if you generate traffic or keep resources running.
**Always run Destroy when you’re done**.

---

## Destroy (cleanup)
From GitHub Actions:
- Run **Destroy (Production)** workflow

Or locally:
```bash
cd infra/production
terraform init -backend-config="bucket=YOUR_BUCKET" -backend-config="dynamodb_table=YOUR_TABLE" -backend-config="key=production/terraform.tfstate" -backend-config="region=YOUR_REGION"
terraform destroy
```

---

## Customize the message
Edit:
- `app/index.html`

Then run **Deploy Website** again.
