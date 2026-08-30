# lambda — the chatbot

The AI assistant behind `/api/chat`. DECISIONS.md #11, #12, #20, #29;
ADR-0003, ADR-0004, ADR-0006.

| | |
|---|---|
| Runtime | Node 22, arm64, 512 MB, 29s timeout |
| Surface | Lambda Function URL, `AWS_IAM` auth, reachable only via CloudFront OAC |
| Model | Claude Haiku 4.5 **via Amazon Bedrock**, 400-token replies, cache point on the system prompt |
| Knowledge | `corpus.json` from the site bucket, fetched on cold start, cached in module scope |
| Limits | 10 messages/hour/IP (DynamoDB TTL), 12 turns, 1,000 chars per message |
| Cache | First questions only, exact match after normalisation, keyed by corpus fingerprint, 7-day TTL (#50) |
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

## There is no API key

The model is called through Bedrock with the function's own execution role
(DECISIONS.md #49), so this stack holds no model credential at all — nothing to
create, rotate, or leak. The IAM grant is one `bedrock:InvokeModel` bound to a
single model id.

**It must be invoked through an inference profile.** In ap-southeast-1 the
foundation model reports `inferenceTypesSupported: ["INFERENCE_PROFILE"]`, so
passing the bare model id fails validation with an error that does not say why:

```bash
aws bedrock list-inference-profiles --region ap-southeast-1
aws bedrock get-foundation-model --region ap-southeast-1   --model-identifier anthropic.claude-haiku-4-5-20251001-v1:0   --query 'modelDetails.inferenceTypesSupported'
```

Both ids are Terraform variables (`bedrock_model_id`,
`bedrock_foundation_model_id`). The IAM policy needs both: the call names the
profile, the profile routes to the model, and Bedrock authorises each
separately — allowing only the profile fails at invoke time with an
access-denied naming the *model*, which reads like a model-access problem
rather than a policy one.

## Reading the logs

Each answered question emits one JSON line: the question, whether it was a
cache hit (`cached`), turn count, token counts, and latency. Hit rate is
`cached:true` over all `event:chat` lines — worth watching, because it is what
decides whether the cache is earning its place. The IP is absent by construction —
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
