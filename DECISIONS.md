# DECISIONS.md — joaqs.online

Chronological record of every design decision for Luis Zara's portfolio site.
Settled across seven rounds of structured questioning on **2026-08-25 → 2026-08-27**.
This is the "why did I do it that way" file, written for me. The terse
interviewer-facing versions live in `docs/adr/`.

**Status:** all 45 decisions settled. M0 built 2026-08-28; M1 applied 2026-08-30 and the site is
live. Next step is M2 in [PLAN.md](PLAN.md).

The raw source conversation is kept privately and is deliberately not in this repository. It is an
unedited planning transcript containing personal details — a phone number and home address among
them — that have no business in a public repo. This file is the curated record; nothing of
substance was left behind in the transcript.

---

## Context at the time of these decisions

- BSIT, UST, Network & Security track, graduated **May 2026**
- AWS **DOP-C02**, **SAA-C03**, **SOA-C03**; AI Practitioner in progress
- Noventiq delivery intern, Feb–Jun 2026
- **Open to work** as of 2026-08-27 — Quezon City, hybrid around Metro Manila, or remote
- GitHub handle: `luiszaragh` (renamed from `soreingh` during Round 2)
- Repos that exist: `DevOps-CICD-Pipeline-Project` (real), `3-Tier-Application-Setup-in-AWS` (real),
  `Altiora` (docs only), `Project-JobTracker` (planning only), `laundry-app` (planning only)

---

## Round 1 — the trunk

### 1. Who the site is for
**Hiring asset**, aimed at recruiters and hiring managers for Cloud/DevOps roles. Not a
personal creative presence.
**Why:** in the market now. Creativity makes the site *memorable* after it has done its
job — it is not what the site leads with.

### 2. The site is a portfolio artifact, not a shop window
Terraform-provisioned S3 + CloudFront, GitHub Actions OIDC deploy, no long-lived keys.
**Deliberately chose the more expensive, more laborious path over click-to-deploy hosting.**
**Why:** a DevOps candidate whose portfolio deploys by clicking a button in Vercel is leaving
the single most on-message point on the table. The infrastructure *is* the artifact.
**Do not revisit this and suggest Netlify/Vercel/Cloudflare Pages — it was chosen against the
cheaper option on purpose.**

### 3. One interactive feature in v1 — the AI chatbot
Blog deferred (later promoted, see #27). **Live chatroom cut entirely.**
**Why:** the chatroom gives strangers an unmoderated write channel and gives a recruiter at
11pm silence — worst effort-to-signal ratio of the three. The chatbot is built as an
*infrastructure* piece, not a widget, so it is simultaneously the creative hook, a serverless
demo, and ten minutes of interview material.

### 4. Projects at launch
Superseded by #8 and #39. Original call: DevSecOps pipeline + UST capstone only, no
placeholder cards.
**Why:** a "coming soon" project card actively costs credibility.

### 5. Budget
**~$5/mo target, hard AWS Budget alarm at $10** → SNS → email, defined in Terraform.
$100 in AWS credits available.
**Why:** a cost control that isn't in code is exactly the thing an interviewer asks whether
you actually did.

### 6. Timeline
No hard deadline. Ship ugly-but-real over perfect-and-unshipped.
**Why:** "no rush" must not become "no launch."

### 7. How literal the WordPad metaphor is
**Hybrid (c)** — document body with functional chrome as signature moments. Not full
skeuomorphism.
**Why:** full skeuomorphic chrome is charming for five seconds and then it is a usability
problem on a phone, which is where half of recruiter traffic lands.

---

## Round 2 — content, stack, metaphor

### 8. Revised project lineup
3-Tier leads, DevSecOps second, UST capstone third (framed as professional work).
**Altiora cut entirely** until it has code. Superseded in part by #39/#43.
**Why:** Altiora is 33 markdown files and zero lines of code — it reads finished until
someone clicks through, which is worse than a "coming soon" card. (It later turned out to be
a private repo anyway, which solves it for free — keep it private.)

### 9. Identity
GitHub renamed to **`luiszaragh`**. Public title: **"Luis Zara — Cloud & DevOps Engineer."**
**Why:** three handles in play (`luiszara`, `soreingh`, real name) made a recruiter do
reconciliation work. The site's whole job is to be the one link that ties them together.
*Open task: local git remotes in the old repos may still say `soreingh` — `git remote set-url` them.*

### 10. Frontend stack — Astro
**Why:** it is the only option where "add a blog later" is genuinely a drop-a-`.md`-in-a-folder
operation, and it outputs a plain static folder so the S3/CloudFront path stays trivial.
Node 24 already installed.

### 11. Chatbot backend, model, grounding
**Lambda Function URL + Claude Haiku 4.5 (`claude-haiku-4-5-20251001`) + full context stuffing
with prompt caching.** No API Gateway. No RAG. CloudFront in front of the Function URL so
there is one origin and WAF can be added later without moving anything.
**Why:** RAG over a six-document corpus is résumé-driven development — an interviewer who knows
the space reads it as over-engineering. A cached ~5k-token system prompt costs a fraction of a
cent per conversation.

### 12. Chatbot guardrails and failure mode
Per-IP rate limit in **DynamoDB, 10 messages/hour** · **400-token** cap per reply ·
**12-turn** conversation cap · system prompt scoped to "answer only from the provided profile,
decline anything else and point to email" · prompts logged to **CloudWatch, 30-day retention** ·
**on budget cap: degrade to a canned message, never a broken widget.**
**Why:** it is a public LLM endpoint with a real API key behind it — the one genuinely risky
thing on the site. A recruiter hitting a JS error is worse than no chatbot. And the logs are
real product insight into what recruiters actually ask.

### 13. Repo layout, state, region
**Monorepo** (`site/` `lambda/` `infra/` `docs/adr/`) · **S3 backend with native S3 locking**
(Terraform ≥1.10, no DynamoDB lock table), bootstrapped once by hand and documented in an ADR ·
**`ap-southeast-1`** for Lambda/DynamoDB, **`us-east-1` for the ACM cert**.
**Why:** separate infra repos make sense at team scale and are pure friction for one person.
Local state on a portfolio project is exactly the shortcut an interviewer probes for. The
us-east-1 ACM requirement is a classic CloudFront gotcha — calling it out in an ADR is free points.

### 14. Information architecture
About first, **certifications at 02**, and **every project gets a dedicated page**
(problem → architecture diagram → key decisions → what broke → outcome).
**Why:** a card says "I did a thing"; a page with an architecture diagram and a "what I'd do
differently" section is what gets you past a technical screen.

### 15. Contact details that go public
Publish a **web-variant résumé PDF with the phone number stripped**, email intact.
No gate, no contact form in front of it.
**Why:** a résumé on a public site is scraped within days. The email is already public in every
git commit, so hiding it achieves nothing. A form between a recruiter and a résumé loses more
than it saves.

### 16. The design, concretely
**Title bar** (`luis_zara.rtf`) · **menu bar that is real navigation** · **status bar that shows
something genuinely live**. No ruler, no toolbar. Mono chrome, serif body. Light default with a
dark toggle. **Chatbot dressed as a Help dialog** with a small persistent hint so people find it.
Mobile: menu collapses to a hamburger, status bar stays.
**Why:** decorative chrome is a costume; functional chrome is a design idea. Only the second
survives someone looking at it twice.

---

## Round 3

### 17. Domain and site repo
**`joaqs.online`** — already owned, registered at **GoDaddy**, DNS at **Cloudflare**, paid a year.
Repo **`luiszaragh/joaqs.online`, public**.
**Why:** "joaqs" is the nickname, so it connects. Route53 drops out entirely because DNS already
lives at Cloudflare — cheaper, one less moving part. Public repo because for a DevOps portfolio
the Terraform *is* the artifact; a private infra repo wastes the best part of the project.
**Constraint accepted: zero secrets in git, ever.**

### 18. The UST capstone
Publish a **sanitized** version. Luis writes the summary himself.
**Why:** this is a real organization's live network. Publishing VLAN topology, ACL structure,
the FreeRADIUS/DHCP/Samba layout, and firewall models hands a blueprint to anyone who wants in.
The reasoning is the valuable part anyway — *why* role-based segmentation, *why* RADIUS over
PSK, *why* 30% spare capacity — and none of that needs a real IP.
**Hard line: no real subnets, hostnames, device models, IP ranges, or the school's name.
Anonymized to "a review center serving 500+ users."**

### 19. The About section
- **Status:** open to work, entry-level/associate
- **Positioning:** Cloud/DevOps with a security lean (see #26)
- **Location:** Quezon City · hybrid around Metro Manila · open to remote — stated **prominently**
- **Fourth cert:** listed as **"In progress"** — *Luis overruled the recommendation to stay
  silent; his call, so it ships in a visually distinct row*
- **The human line, to be used close to verbatim:**
  > My interest in infrastructure started with networking. I liked understanding how devices
  > communicate, what happens behind the scenes when you access a service, and eventually how
  > those same concepts translate into cloud environments.

**Why (location):** it is the single most common thing a recruiter filters on and the most
common thing missing from junior portfolios.

### 20. Chatbot persona and knowledge source
**Third person, clearly labeled as an AI** ("AI assistant — answers from Luis's résumé and
project docs; it can be wrong"). Knowledge **generated at build time from the site's own content**.
**Why:** first person is a trap — the moment it hallucinates a skill Luis doesn't have, an AI is
misrepresenting his qualifications to an employer, in writing. Build-time corpus generation means
one source of truth and drift is impossible by construction.
**Never make this bot speak as Luis.**

### 21. The pipeline
**Three path-filtered workflows** (`site.yml` / `lambda.yml` / `infra.yml`) ·
`terraform plan` on PR posted as a PR comment, **`apply` on main behind a GitHub Environment
approval** · **one least-privilege OIDC role per workflow** ·
**mandatory gates:** astro build, Gitleaks, tflint, checkov, link checker ·
**advisory:** Lighthouse.
**Why:** manual approval on apply is the habit an interviewer wants to see and costs one click.
Given the résumé leads with DevSecOps, Gitleaks and checkov are not decoration here — they are
the thesis. A public infra repo with secret scanning in CI proves the exact claim being made.

### 22. Analytics
**CloudFront standard logs → S3**, 90-day lifecycle expiry, queried with **Athena** on demand.
No JS, no cookies, no consent banner, no hosted product.
**Why:** free, zero privacy surface, and "I query my own access logs with Athena" is a better
line than "I installed a script tag." Referrers show whether recruiters actually click through
from LinkedIn.

### 23. Final IA and chrome contents
Order: `00` header · `01` about · `02` certifications · `03` projects · `04` blog ·
`05` experience · `06` skills · `07` contact.
- **Title bar:** `luis_zara.rtf`
- **File:** download résumé · copy email · view source
- **View:** dark mode toggle · jump to section
- **Help:** ask the AI assistant · about this site
- **Edit menu: dropped entirely**
- **Status bar:** current section · **deployed commit SHA, linking to that commit on GitHub** ·
  build timestamp
- **Favicon:** a document glyph

**Why (dropping Edit):** an Edit menu with nothing real under it is exactly the decorative-chrome
failure mode. Three working menus beat four where one is a costume.
**Why (the SHA link):** that single detail tells any engineer the site is CI-deployed and that
Luis knows it matters.

---

## Round 4

### 24 / 32. joaqs.online's existing setup
GoDaddy Website Builder **not in use** — what's live is a "Launching Soon" placeholder with
nothing worth keeping. **Cloudflare DNS records managed in Terraform via the `cloudflare` provider.**
**Grey cloud / DNS-only, non-negotiable.**
**Why (grey cloud):** pointing a proxied orange-cloud record at CloudFront stacks two CDNs — an
extra latency hop, SNI/cert awkwardness, and the killer: **CloudFront's access logs record
Cloudflare's edge IPs instead of visitors' IPs**, which silently destroys decision #22.
**Why (DNS in Terraform):** a two-provider config managing a real cross-vendor stack is a
meaningfully better interview artifact than "I clicked around in a dashboard," and it makes the
eventual domain migration a variable change.

### 25. Designing for the domain migration that is already coming
**The domain lives in exactly one Terraform variable (`var.domain_name`) and one Astro config
value (`site.url`).** Canonical URLs are generated from that value. **Never a literal domain
string anywhere else.**
**Why:** `.online` reads as a discount TLD to a screener and "joaqs" is not the legal name, so a
migration to a real-name domain is coming. Done from line one it costs nothing; migration day
becomes buy domain → change two values → apply → add a redirect.
**Also:** hold off putting `joaqs.online` on the résumé and LinkedIn until it is certain to stay
a while — a dead link on a résumé is worse than no link.

### 26. Positioning
**H1: "Luis Zara — Cloud & DevOps Engineer."** One label, no slashes.
Subline: *"AWS-certified (DOP-C02, SAA-C03, SOA-C03) · Open to Cloud/DevOps roles — Metro Manila,
hybrid, or remote."*
**The word "Junior" does not appear in the H1** — it goes in About instead ("BSIT, UST, 2026 —
open to entry-level and associate roles").
**Why:** a junior who lists Cloud / DevOps / Platform / SRE / Security reads as someone who
hasn't chosen, and screeners pattern-match on one label. The actual evidence — three AWS certs
including a Professional, a Terraform/EKS/RDS build, a 15-stage DevSecOps pipeline, M365/Entra
identity work — is narrower and stronger than the self-description. Let the *projects* demonstrate
the breadth; showing beats claiming. "Junior" in an H1 is an invitation to be filtered and a
lowball anchor.

### 27. Blog — promoted to launch
Scaffolded now **and shipping at launch**, because post #1 is "how this portfolio is deployed."
**Why:** the friction of setting up the pipeline is precisely what kills the first post six months
later. And that is the right first post — the only topic where the artifact and the writing prove
each other. The Round-1 rule (no nav link until a post exists) is satisfied on day one.

### 28. Contact
**Click-to-copy email button with a "copied!" confirmation**, next to LinkedIn and GitHub links.
No form, no `mailto:`.
**Why:** a form means another Lambda, another endpoint to rate-limit, spam handling, and a
deliverability problem — real work for something recruiters ignore in favor of emailing directly.
`mailto:` breaks on desktops with no mail client configured.

### 29. Corpus delivery and environments
**Corpus written to S3 by the site build, fetched by the Lambda on cold start, cached in module
scope. Prod only — no staging, no PR previews.**
**Why:** baking the corpus into the Lambda bundle would quietly re-couple `site.yml` and
`lambda.yml`, defeating the point of splitting them in #21. A staging environment for a personal
site reads as ceremony rather than judgment — deferred until it would catch something the CI
gates don't, and that reasoning goes in an ADR.

### 30. Type and color
**Self-hosted, Latin-subset fonts** — **Source Serif 4** body, **IBM Plex Mono** chrome.
Warm off-white paper **`#faf8f5`**, near-black ink **`#111`**. Dark toggle under View.
**Why:** self-hosting is faster (no third-party DNS + TLS handshake) and on a site whose entire
premise is "I control my own infrastructure," pulling fonts from a Google CDN is a small
contradiction someone might notice. Warm paper sells the document metaphor; true white doesn't.

### 31. Where the decisions live
**Both:** this `DECISIONS.md` (chronological, for Luis) **and ~6 sharp ADRs** under `docs/adr/`
(for interviewers). Budget alarm at $10/mo in Terraform.
**Why:** they serve different readers. Six sharp ADRs beat thirty shallow ones.

---

## Round 5

### 33. Blog placement and scope
**Blog at `04`**, after projects, pushing experience/skills/contact down. **RSS yes, tags no.**
**Post #1 derived from the ADRs** so they cannot drift. **Chatbot corpus includes everything** —
blog posts, capstone summary, projects, résumé.
**Why:** certs and projects are what a screener needs; the blog is what a fellow engineer reads
once already interested, so it sits right after the projects that earned that interest. Tags on
one post is scaffolding for an audience that doesn't exist. A bot that can't discuss the thing
just published looks broken.

### 34 / 40. The 3-Tier rename
**Repo → `aws-eks-three-tier`. App inside → "Tasklet."** README rewritten so the *infrastructure*
is the subject and the app is explicitly incidental. **`Project-JobTracker` keeps its name.**
**Why:** the current README sells a job tracker; nobody is hiring Luis to build CRUD. The
hireable content is the Terraform, IRSA, Secrets Manager, ACM, probes, non-root containers, and
the budget-alarm auto-pause Lambda.

### 35. Capstone timing
**Launch is not blocked on it.** The page slot exists; the page lands when the sanitized summary
is written. Sanitization line from #18 holds **even if the school says it's fine**.
**Why:** publishing a live client's network topology is the kind of judgment lapse a
security-minded interviewer will notice. "I chose to anonymize it" is a better answer than any
diagram.

### 37. The résumé PDF
**(a) for now:** hand-export a web variant with the phone number removed, commit as `resume.pdf`.
**(b) résumé-source-in-repo built to PDF in CI is a deliberate deferral, recorded here.**
**Plus a Gitleaks custom rule that fails CI if the phone number string ever appears in the repo.**
**Why:** a résumé-to-PDF pipeline is a fun rabbit hole that eats a weekend and delays launch for
a file updated twice a year. The Gitleaks rule is ten lines and permanently prevents the mistake.

### 38. Open Graph
**One static OG image** for the whole site, in the WordPad aesthetic. Not per-page generation.
**Why:** this link gets pasted into LinkedIn posts, applications, and DMs — a link with no preview
card looks broken, and that's the first impression before anyone clicks. Per-page generation is
over-engineering for a four-page site.

---

## Rounds 6 & 7

### 39 / 43. Where 3-Tier sits
**Design the slot now, fill it later.** Launch ships with **DevSecOps as the only project**;
3-Tier lands when the rework is done, as a **project page plus a blog deep-dive**.
**Why:** the project page is for the screener with 40 seconds; the blog post is for the engineer
already interested. Same material, two depths, and the deep-dive gives the blog a second piece.
**Risk on the record:** "I'll rework it tomorrow" can become a month — the launch must not be
blocked on it.
*Tracked separately as the 3-tier rework project: infrastructure is the product, the app is a vehicle.*

### 41 / 44 / 45. The ASCII graduation portrait
Replaces the headshot entirely.
- **Generated at build time while tuning locally**, then the finished `.txt` is committed
- **Real selectable text in a `<pre>`**, not an image
- **Monochrome**
- **The original photograph never ships, and is gitignored — it never enters a public repo**
- Needs a real `alt` (`"ASCII portrait of Luis at his 2026 graduation"`) because a screen reader
  hitting 2,000 punctuation characters is a disaster
- Needs a **narrower character-width variant under ~640px** — ASCII art does not reflow

**Why:** it resolves the headshot tension exactly — human presence without a photo competing with
the certs, fits the document metaphor better than a headshot ever would, and sidesteps
appearance-bias entirely because no face is ever published. Text over image is the point: someone
selects it, copies it, and discovers it is actual characters.

### 41(b). Capstone install photos
Ship on the capstone page, **treated as sanitization targets**: **EXIF stripped at build time as
a CI gate** (not a manual step — manual steps get forgotten), each image reviewed individually for
device labels, monitors, hostnames, badges, and faces.
**Why:** a photo of a real client's rack can expose more than a sanitized topology ever would,
and **every phone photo carries GPS coordinates and a timestamp** — publishing them geotags the
school's server room to the meter. Photos of *Luis doing the work* (hands on a switch, running
cable) are better portfolio content anyway and far easier to sanitize.

---

## Deferred, on the record

- Résumé-source-to-PDF pipeline in CI (#37)
- Staging environment and PR previews (#29)
- Blog tags (#33)
- Per-page OG images (#38)
- Altiora, Project-JobTracker, laundry-app — all pre-code, none ship (#8)
- Migration to a real-name domain (#25)
- WAF in front of the Lambda Function URL (#11 — the architecture leaves room for it)

## Open threads

- [ ] Write the **sanitized capstone summary** — blocks the capstone page only (#18, #35)
- [ ] Rework **`aws-eks-three-tier`** — blocks the 3-Tier project page and deep-dive (#39, #43)
- [ ] Confirm no GoDaddy Website Builder line item is still being billed (#24)
- [ ] `git remote set-url` the old `soreingh` remotes in the four existing repos (#9)
- [ ] Tune the ASCII portrait locally and commit the `.txt` (#44)
