# aws-react-terraform-spa

A template for a React single-page app on AWS: S3 behind CloudFront, deployed by GitHub Actions, with every AWS resource in Terraform except the Route53 hosted zone, which you bring.

- **App:** React 19, TypeScript, Vite, Vitest, ESLint, Yarn 4.
- **Hosting:**
  - A private S3 bucket reached only through CloudFront Origin Access Control.
  - An ACM certificate.
  - HTTP/2 and HTTP/3, TLS 1.2+.
  - Security headers, including a same-origin-only Content Security Policy.
  - SPA routing: unknown paths serve `index.html`.
- **CI/CD:** GitHub Actions over OIDC, with no stored AWS keys.
  - Pull requests run checks and a read-only `terraform plan`.
  - `main` applies, uploads and invalidates the CloudFront cache.

## Using the template

You need an AWS account with a public Route53 hosted zone for your domain, already delegated from your registrar, plus the AWS CLI, Terraform 1.17+, `gh`, and Node 24 with Corepack.

1. **Create your repo** with **Use this template** on GitHub, and clone it.

2. **Bootstrap AWS, once,** with admin credentials for the account. This creates:
   - an S3 bucket for Terraform state;
   - GitHub's OIDC provider;
   - a **deploy** role that only `main` can assume, scoped to this site's bucket, zone records, CloudFront and ACM;
   - a read-only **plan** role for pull requests.

   ```sh
   cd infrastructure/terraform/bootstrap
   cp terraform.tfvars.example terraform.tfvars   # set github_repository and domain_name
   terraform init
   terraform apply
   ```

   If the account already has GitHub's OIDC provider, set `create_github_oidc_provider = false`.

3. **Point GitHub at it.** The `github_variables` output is a list of ready-to-run commands:

   ```sh
   terraform output -raw github_variables | sh
   ```

   | Variable | Required | Purpose |
   | --- | --- | --- |
   | `AWS_DEPLOY_ROLE_ARN` | yes | Role `main` assumes to apply and upload |
   | `AWS_PLAN_ROLE_ARN` | yes | Read-only role pull requests assume to plan |
   | `TF_STATE_BUCKET` | yes | Bucket for the site's Terraform state |
   | `DOMAIN_NAME` | yes | Hostname to serve, e.g. `example.com` or `app.example.com` |
   | `HOSTED_ZONE_NAME` | no | Zone holding `DOMAIN_NAME`, if it isn't `DOMAIN_NAME` itself |
   | `INCLUDE_WWW` | no | `false` to skip `www.<domain>`, usually for subdomains (default `true`) |
   | `AWS_REGION` | no | Region for the buckets (default `us-west-2`) |

4. **Push to `main`.** The first deploy creates everything and takes about 10 minutes, mostly CloudFront. After that, deploys take a couple of minutes.

Until `AWS_DEPLOY_ROLE_ARN` and `AWS_PLAN_ROLE_ARN` are set, CI only lints, tests and builds. That's why this template repo itself never deploys.

## Local development

```sh
corepack enable
yarn install
yarn dev        # http://localhost:5173
yarn lint
yarn test:ci
yarn build      # dist/
```

To run the site's Terraform locally, use the same backend and variables CI does:

```sh
cd infrastructure/terraform/site
cp terraform.tfvars.example terraform.tfvars
terraform init -backend-config="bucket=<TF_STATE_BUCKET>" -backend-config="key=site/terraform.tfstate" -backend-config="region=us-west-2"
terraform plan
```

## Layout

| Path | What |
| --- | --- |
| `src/`, `public/`, `index.html` | The app. Files in `public/` are served as-is. |
| `infrastructure/terraform/bootstrap/` | One-time setup: state bucket, OIDC provider, deploy and plan roles. Local state. |
| `infrastructure/terraform/site/` | The site: bucket, CloudFront, certificate, DNS records. Applied by CI. |
| `.github/workflows/` | `on-pr.yml` checks and plans; `on-push.yml` checks and deploys `main`. |

## Things to know

- **Content Security Policy.**
  - The default allows only the site's own origin.
  - It blocks inline scripts and styles, and anything from a CDN or third-party API.
  - Vite's production build needs nothing more.
  - If the app loads anything else (fonts, analytics, an API on another domain), add it to `content_security_policy` in [`site/variables.tf`](infrastructure/terraform/site/variables.tf).
- **Caching.**
  - Hashed files in `dist/assets/` are cached for a year.
  - Everything else, including `index.html`, revalidates on every request, so a deploy shows up right away.
  - Old assets stay in the bucket so tabs that are already open keep working.
- **Bootstrap state** lives in `bootstrap/terraform.tfstate` on the machine that ran it. It only describes the bucket and roles, so losing it isn't fatal: re-import them, or recreate the roles. To keep it with everything else, add `backend "s3" {}` to `bootstrap/versions.tf` and run `terraform init -migrate-state` with the same `-backend-config` flags and `key=bootstrap/terraform.tfstate`.
- **Tearing down.**
  - Empty the site bucket, then run `terraform destroy` in `site/`.
  - The state bucket has `prevent_destroy`; remove it deliberately to destroy `bootstrap/`.
