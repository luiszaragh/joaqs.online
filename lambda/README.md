# lambda — the chatbot

The AI assistant behind `/api/chat`. DECISIONS.md #11, #12, #20, #29;
ADR-0003, ADR-0004, ADR-0006.

| | |
|---|---|
| Runtime | Node 22, arm64, 512 MB, 29s timeout |
| Surface | Lambda Function URL, `AWS_IAM` auth, reachable only via CloudFront OAC |
| Model | Claude Haiku 4.5, 400-token replies, prompt caching on the system prompt |
| Knowledge | `corpus.json` from the site bucket, fetched on cold start, cached in module scope |
| Limits | 10 messages/hour/IP (DynamoDB TTL), 12 turns, 1,000 chars per message |
| Logs | CloudWatch, 30-day retention. Questions are logged; IP addresses are not |

## Deploying

`.github/workflows/lambda.yml`, on pushes touching `lambda/**`. Terraform owns
the function's *existence and configuration*; this workflow owns its *code*.
That split is why `aws_lambda_function.chat` carries
`ignore_changes = [filename, source_code_hash]` — without it, every
`terraform apply` would roll the code back to the placeholder.

The deploy role can call `UpdateFunctionCode` on this one function and nothing
else. Notably it cannot call `UpdateFunctionConfiguration` (which could repoint
`CORPUS_BUCKET` at someone else's bucket) or `PassRole`.

## The API key

In SSM Parameter Store as a SecureString, read at runtime by the execution
role. **It is never passed through Terraform** — a value given to Terraform is
written to state in plaintext, and this repository is public. Terraform holds
the parameter's name and the permission to read it.

Created once, by hand:

```bash
aws ssm put-parameter --name /joaqs-online/anthropic-api-key   --type SecureString --value sk-ant-... --region ap-southeast-1
```

Rotating it is the same command with `--overwrite`. No redeploy is needed for
a cold container; a warm one keeps the old key until it recycles.

## Reading the logs

Each answered question emits one JSON line: the question, turn count, token
counts (including cache reads), and latency. The IP is absent by construction —
it is salted and hashed for rate limiting and never logged in any form.

```bash
aws logs tail /aws/lambda/joaqs-online-chat --follow --region ap-southeast-1
```

## Failure modes

Every path returns a usable sentence with HTTP 200 rather than an error shape.
A recruiter who hits a JS exception is worse off than one who never saw a
chatbot (DECISIONS.md #12), so: rate limited, model unavailable, corpus
unreadable and turn cap reached all end in a written reply pointing at Luis's
email. The widget never breaks; it stops being useful and says so.
