# Interview explanation (talk track)

## What I built
A simple but production-style pipeline:
- Terraform provisions AWS infrastructure (S3 + CloudFront using OAC so the bucket stays private).
- GitHub Actions runs CI checks (fmt/validate/plan) on pull requests.
- GitHub Actions applies infrastructure and deploys the website.

## Why it’s secure
- GitHub authenticates to AWS using **OIDC** (no static AWS keys stored in GitHub).
- The S3 bucket is private with public access blocked.
- CloudFront can read the bucket via a restrictive bucket policy (SourceArn condition).

## Why it’s low-cost
- No EC2, no NAT, no databases.
- PriceClass_100 limits CloudFront regions to reduce cost.
- Destroy workflow removes everything when finished.

## What I would improve next
- Add automated tests (HTML lint / basic security headers)
- Add staging environment with approvals
- Add custom domain + ACM certificate + WAF (if needed)
