# ADR-0003 — Lambda Function URL behind CloudFront, not API Gateway

- **Status:** accepted
- **Date:** 2026-08-30
- **Milestone:** M5
- **DECISIONS.md:** #11, #12

## Context

The chatbot needs one HTTPS endpoint that accepts a POST and returns a reply.
It holds an Anthropic API key, so it is the one component on this site where a
mistake costs real money rather than embarrassment.

The conventional answer is API Gateway in front of Lambda. The alternative is a
Lambda Function URL — an HTTPS endpoint the Lambda service provides directly,
with no gateway in between.

The choice is not obvious, because API Gateway brings genuine features: request
throttling, usage plans, request validation, WAF attachment, custom
authorizers, and per-route configuration. The question is whether any of them
are load-bearing here.

## Decision

A **Lambda Function URL with `AWS_IAM` authorization**, placed behind the site's
existing CloudFront distribution as a second origin on the `/api/*` path, with
requests signed by **Origin Access Control**.

The Function URL is not publicly callable. Its resource policy allows exactly
one principal — `cloudfront.amazonaws.com`, conditioned on the ARN of this one
distribution.

## Consequences

**One hostname, one origin, one place to attach a WAF.** The site and its API
share `joaqs.online`, so the browser makes a same-origin request and there is no
CORS configuration to get wrong. When a WAF is eventually justified, it attaches
to the distribution and covers both. This is the whole reason the endpoint sits
behind CloudFront rather than being called directly.

**No per-request gateway charge, and one less hop.** API Gateway HTTP APIs cost
about $1.00 per million requests. At portfolio traffic that is pennies, so cost
is not the argument — the argument is that a component earning nothing should
not be in the request path.

**The features given up were not being used.** No custom authorizers: the
endpoint is deliberately public. No request validation: the handler validates
its own input, and would have to regardless. No usage plans or API keys: rate
limiting is per-IP in DynamoDB (DECISIONS.md #12), which API Gateway's
per-key throttling does not do anyway.

**What was genuinely lost: API Gateway's built-in throttling.** A Function URL
has no request-rate control of its own. Three things replace it, and they are
not equivalent — they are cheaper and coarser:

1. The per-IP limit in DynamoDB, checked before any model call
2. The `max_tokens` cap of 400, bounding the cost of any single reply
3. The AWS Budget alarm, which is the backstop rather than the control

A determined attacker rotating IPs can still drive up invocation count. What
they cannot do is drive up *model* cost meaningfully, because every request
past the limit is rejected before the API call. That is the exposure worth
bounding, and it is bounded.

**`AWS_IAM` rather than `NONE` is the load-bearing half of this decision.** A
Function URL with `NONE` is an open endpoint on the public internet, reachable
directly by anyone who finds it — bypassing CloudFront, bypassing any future
WAF, straight to the function holding the API key. Discovery is not hard: the
URL shape is predictable and the host appears in CloudFront's origin
configuration. Choosing OAC signing means the only reachable path is the one
with controls on it.

**The cost is one non-obvious failure mode.** OAC signs the request, and Lambda
rejects any request whose signature does not cover the headers it received —
which means the CloudFront behaviour must forward everything *except* the Host
header. That is what `Managed-AllViewerExceptHostHeader` is for. Get it wrong
and every request returns 403 with nothing in the logs to explain why. It is
recorded here because it is the thing most likely to be broken by a future
edit to the cache behaviour.

## Alternatives considered

**API Gateway HTTP API.** Rejected: every feature it adds here is either unused
or already solved closer to the problem. It would be the right answer the moment
there is a second route, a second consumer, or a need for authorizers.

**Function URL with `NONE`, no CloudFront.** Rejected outright. Simpler by one
resource, and it puts an unprotected endpoint holding an API key on the public
internet.

**ALB.** Rejected: about $16/month of fixed cost for a site whose entire
infrastructure targets under $1/month.
