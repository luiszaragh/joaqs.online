# ADR-0002 — Manage Cloudflare DNS in Terraform, DNS-only, with no Route 53

- **Status:** accepted
- **Date:** 2026-08-30
- **Milestone:** M1
- **DECISIONS.md:** #17, #24, #25, #32

## Context

`joaqs.online` is registered at GoDaddy with DNS already delegated to Cloudflare.
The rest of the stack is AWS. Two questions followed: whether to move DNS to
Route 53 for provider consistency, and whether to proxy the records through
Cloudflare's CDN ("orange cloud") or leave them DNS-only ("grey cloud").

## Decision

Keep DNS at Cloudflare, manage the records with the `cloudflare` Terraform
provider alongside the `aws` provider in the same configuration, and set
`proxied = false` on every record.

## Consequences

**No Route 53.** A hosted zone that duplicates a working one is a second source
of truth, a second bill, and a migration for no gain. Dropping it also removed
Route 53 alias records from the design — the apex points at CloudFront by CNAME,
which Cloudflare resolves through CNAME flattening.

**Two providers in one configuration.** The certificate is the seam: AWS issues
it, Cloudflare proves domain ownership by publishing the validation records, and
`aws_acm_certificate_validation` blocks until ACM sees them. This is a more
honest artifact than a single-provider config — most real stacks span vendors —
but it means an apply can now fail for reasons on either side of the boundary.

**Grey cloud is load-bearing, not a preference.** Proxying through Cloudflare in
front of CloudFront would stack two CDNs: an extra latency hop and SNI
awkwardness, and decisively, **CloudFront's access logs would record Cloudflare's
edge IPs instead of visitors' IPs.** The site's analytics plan is CloudFront
standard logs queried with Athena and no client-side JavaScript. Proxying would
silently reduce that to a log of Cloudflare's infrastructure.

**A hazard this created.** The ACM validation records look like disposable
scaffolding and are not. ACM re-validates roughly 60 days before expiry using the
same records. Deleting them leaves the site working for about eleven months and
then failing to renew. Keeping them in Terraform means the drift surfaces in a
`plan` rather than in a browser warning. This happened during the M1 apply and is
the reason it is written down here.

**Migration cost is now one variable.** The domain appears in exactly two places
in the repository: `var.domain_name` and `site` in `site/astro.config.mjs`.
Everything else derives from them.

## Alternatives considered

**Route 53 for everything.** Consistent provider story and native alias records
at the apex. Rejected: it means paying for and maintaining a second authoritative
zone to replace one that already works, and a nameserver migration with a real
window for error.

**Cloudflare records managed by hand in the dashboard.** Fewer moving parts and
no API token to scope and store. Rejected: DNS is the part of this stack where a
mistake is most visible and hardest to reason about after the fact, and
"I clicked around in a dashboard" is a materially weaker artifact than a
cross-vendor configuration under version control.

**Orange cloud for the DDoS protection and caching.** Rejected on the access-log
grounds above. If protection becomes necessary, the architecture leaves room for
AWS WAF in front of CloudFront, which does not disturb the logs.
