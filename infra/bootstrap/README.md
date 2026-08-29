# Bootstrapping the state backend

Run once, by hand, before the first `terraform init`. DECISIONS.md #13.

## Why this is not Terraform

A configuration cannot create the bucket that holds its own state — the backend
has to exist before `init` can talk to it. The usual dodges are a second
Terraform config with local state committed to the repo, or a `-target` dance on
the first apply. Both trade a five-command one-off for a permanent piece of
confusing machinery. Four commands, documented, is the better deal, and "how did
you bootstrap the backend?" is a question worth having a real answer to.

## Commands

PowerShell. Run once, with credentials that can create S3 buckets.

```powershell
$Bucket = "joaqs-online-tfstate-377510222046"
$Region = "ap-southeast-1"

# 1. The bucket itself.
aws s3api create-bucket `
  --bucket $Bucket `
  --region $Region `
  --create-bucket-configuration LocationConstraint=$Region

# 2. Versioning. This is the undo button for a corrupted or truncated state
#    file, and it is the single most valuable setting here.
aws s3api put-bucket-versioning `
  --bucket $Bucket `
  --versioning-configuration Status=Enabled

# 3. Encryption at rest.
aws s3api put-bucket-encryption `
  --bucket $Bucket `
  --server-side-encryption-configuration '{\"Rules\":[{\"ApplyServerSideEncryptionByDefault\":{\"SSEAlgorithm\":\"AES256\"},\"BucketKeyEnabled\":true}]}'

# 4. Block public access, all four settings. State files contain resource
#    identifiers and occasionally more; none of it should ever be reachable
#    from the internet.
aws s3api put-public-access-block `
  --bucket $Bucket `
  --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

Verify:

```powershell
aws s3api get-bucket-versioning --bucket $Bucket
aws s3api get-public-access-block --bucket $Bucket
```

Then, from `infra/`:

```powershell
terraform init
```

## No DynamoDB lock table

The backend uses `use_lockfile = true`, which locks via an S3 conditional write
that drops a `.tflock` object next to the state. That went GA in Terraform 1.11,
which is why `required_version` is `>= 1.11`. DynamoDB-based locking still works
but is deprecated, and for a single-operator project a second service purely to
hold a lock row was never a good trade.

## If you ever need to start over

The state bucket is deliberately not managed by Terraform, so `terraform
destroy` will not touch it. Deleting it is a manual act, and it should be —
with versioning on, emptying it requires deleting every version, which is
enough friction to make you think first.
