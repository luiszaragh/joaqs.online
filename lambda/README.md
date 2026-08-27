# lambda — the chatbot

Lands in **M5**. Nothing here yet by design; `lambda.yml` is path-filtered on
`lambda/**`, so an empty directory means no deploys fire.

Shape it will take (DECISIONS.md #11, #12, #20, #29):

- **Runtime surface:** Lambda Function URL, reached through CloudFront so there
  is one origin and WAF can be added later without moving anything.
- **Model:** Claude Haiku 4.5 (`claude-haiku-4-5-20251001`), full-context
  stuffing with prompt caching. No RAG.
- **Corpus:** written to S3 by the *site* build, fetched on cold start, cached
  in module scope. Never bundled into the deployment package — bundling would
  re-couple `site.yml` and `lambda.yml`.
- **Guardrails:** 10 messages/hour per IP (DynamoDB), 400-token replies,
  12-turn conversation cap.
- **Persona:** third person, labelled as an AI, scoped to decline anything
  outside the profile. **It never speaks as Luis.**
- **Failure mode:** budget cap reached → a canned message, never a broken widget.
- **Logs:** prompts to CloudWatch, 30-day retention.

## The API key

Never in this repo, never in an environment variable in Terraform state in
plaintext. It is a Secrets Manager (or SSM SecureString) reference resolved at
runtime by the function's execution role. This repo is public.
