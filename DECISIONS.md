# DECISIONS.md — joaqs.online

Chronological record of every design decision for Luis Zara's portfolio site.
Settled across seven rounds of structured questioning on **2026-08-25 → 2026-08-27**.
This is the "why did I do it that way" file, written for me. The terse
interviewer-facing versions live in `docs/adr/`.

**Status:** all 45 decisions settled. M0 built 2026-08-28; M1 and M2 landed 2026-08-30 — the site
is live and deploys from `main` over OIDC with no long-lived AWS keys. Next step is M3 in
[PLAN.md](PLAN.md).

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

### 46. Design revision — less costume, more page (2026-08-30)
Luis reviewed the built site and pulled the metaphor back: the WordPad framing was read as a
literal WordPad clone, which was never the intent. What changes:
- **Title bar deleted** (`luis_zara.rtf`). It was the one chrome element that did nothing; now
  everything on screen does something. Menu bar and status bar stay.
- **Help menu deleted.** "About this site" was three paragraphs in a dialog; that material is the
  blog's first post, where it gets the room it deserves. The M5 chatbot loses its planned Help-menu
  home and will get a new one when it lands — decided then, not now.
- **Blog gets its own page** at `/blog`. The home section becomes a table of contents — titles from
  a shared data file (`site/src/data/posts.ts`) plus an "All posts" link — so the two lists cannot
  disagree.
- **Section headers listed down the left margin** on wide screens, driven by the same
  IntersectionObserver as the status bar: one source of "where is the reader", two displays.
- **Scroll-reveal animations**: sections fade up as they enter the viewport, and each heading
  builds letter by letter — a progress readout, which suits an infrastructure portfolio. Every
  hidden initial state is gated on a `data-animate` flag set only when JavaScript runs and the
  reader has not asked for reduced motion, so no-JS and reduced-motion readers get a plain,
  fully-visible page.
- **Certification tier icons** — hexagons in AWS's tier colours, drawn inline rather than shipping
  Credly's trademarked badge art; in-progress renders as a dashed outline.
- **The résumé download saves as** `ZARA, Luis Joaquin_Resume.pdf` — surname-first, the way a
  recruiter's folder expects — via the `download` attribute.

**Why:** the margins and the document feel survive; the parts that read as costume go. Supersedes
the title-bar and Help-menu items of #16/#23; everything else in those decisions stands.

---

### 47. Second design revision — the navigation panel, and the photograph ships (2026-08-30)
Follow-up to #46 after Luis reviewed it against a reference layout. What changes:
- **The left-margin section list becomes a full navigation panel**: fixed, full height, separated
  from the document by a rule. Name at the top, the numbered sections down the middle, the résumé
  download at the bottom. Lives in the layout, so the blog and project pages carry it too — its
  links are root-anchored (`/#about`) for exactly that reason. Hidden below 60rem.
- **The View menu is deleted entirely.** The panel does its jumping; the theme toggle it held
  moves onto the menu bar itself, where it works at every screen size. The menu bar is now File
  plus the toggle, and the mobile hamburger went with it — one menu needs no collapsing. On
  phones, section jumping is gone with the panel; accepted, the page is a single scroll there.
- **The ASCII portrait comes off the page; the photograph ships.** This consciously reverses the
  never-publish-the-face clause of #41/#44/#45 — Luis's call on his own photo. The safeguards
  move rather than vanish: the committed copy is EXIF-stripped and resized by
  `scripts/portrait/prepare-web.mjs`, which verifies the metadata is gone and refuses otherwise;
  the original stays gitignored. The photo sits left of the About paragraph. The ASCII generator
  and its `.txt` output stay in the repo, unrendered — "for now", per Luis.
- **The masthead carries the full name** — Luis Joaquin V. Zara — via `profile.fullName`; the
  short form stays in the browser tab, sidebar brand, and OG metadata.

**Why:** the margin list read as an afterthought; a panel with a rule reads as structure. And a
portfolio photographed in a toga says "2026 graduate" faster than any paragraph — the
appearance-bias argument of #45 lost to being recognisably a person.

---

### 48. M5 as built — where the assistant lives, and what it cost to place it (2026-08-30)
The chatbot was specified in #11/#12/#20/#29 and planned to open from a Help menu that #46 then
deleted. Resolved by putting it in the sidebar above the résumé — a persistent button showing its
Alt+K shortcut, which is how people actually find these — rather than reinstating a menu that
existed to hold one item.

Built as specified, with these details settled during the work:
- **SSM Parameter Store SecureString, not Secrets Manager**, for the API key. Secrets Manager is
  $0.40/secret/month on a stack targeting under $1/month, for rotation and cross-account sharing
  this does not use. The key is created by hand and **never passed through Terraform** — a value
  given to Terraform is written to state in plaintext, and this repo is public.
- **The Function URL is `AWS_IAM`, signed by CloudFront OAC.** `NONE` would put an open endpoint
  holding an API key on the internet, reachable directly, bypassing the CDN and any future WAF.
- **Terraform owns the function; the pipeline owns its code** (`ignore_changes` on the package).
  Without that split every `terraform apply` would roll the code back to the placeholder.
- **The rate limiter stores a salted hash, never an IP.** A bare SHA-256 of an IPv4 address is
  brute-forceable in seconds, so the salt is what makes the row a pseudonym. Rows expire by TTL
  within the hour; questions are logged, addresses never are.
- **The corpus gate is a build failure above 120 kB.** #11 chose context stuffing over RAG on the
  grounds that the corpus is small. That premise now fails the build when it stops being true,
  rather than quietly costing more per request.

Three new Checkov findings, all triaged rather than suppressed. The one worth naming: **Lambda
code signing (CKV_AWS_272) was skipped on a boundary argument, not a cost one** — a Signer profile
would live in the same account and be used by the same pipeline, restating the trust boundary that
`joaqs-online-lambda-deploy` already draws instead of adding one. It becomes worth doing the day
signing authority can sit where the deploy pipeline cannot reach it.

**Why the sidebar and not a floating bubble:** a bubble is the shape of a support widget, and the
one thing this must not be mistaken for is a person offering help. The label — *"AI assistant.
It can be wrong."* — is in the dialog header where it is read before any answer, not in a tooltip.

---

### 49. Bedrock instead of the Anthropic API — no card, and no API key either (2026-08-30)
#11 named Claude Haiku 4.5 and assumed the Anthropic API. That needs a funded card, which Luis
does not have right now. **Same model, reached through Amazon Bedrock instead**, billed to the
AWS account the $100 in credits already covers.

Verified before committing to it: `anthropic.claude-haiku-4-5-20251001-v1:0` is offered in
ap-southeast-1, and must be invoked through the `global.` **inference profile** — the foundation
model reports `inferenceTypesSupported: ["INFERENCE_PROFILE"]`, so a bare model id fails
validation with an error that does not explain itself. Bedrock access on this account was still
mid-verification at the time of writing (AWS does this on first use; under two hours), so the
first real invocation is the thing left to confirm.

This is not a downgrade dressed as a workaround — **it removes a whole class of risk**:
- **There is no API key anywhere in this stack.** No SSM SecureString, no manual creation step,
  no rotation, nothing to leak. The Lambda calls the model with its own execution role.
- The IAM policy shrinks: `ssm:GetParameter` and a `kms:Decrypt` grant are replaced by one
  `bedrock:InvokeModel` bound to a single model id.
- The claim the whole repo makes — *no long-lived credentials* — now covers the chatbot too,
  where before the chatbot was the one exception.
- Spend lands on the existing budget alarm rather than on a separate bill nobody is watching.

The one real cost: **Bedrock is a second place model availability can differ**. A region that
does not offer this model, or an inference profile that changes name, breaks the call in a way
the Anthropic API never would. Both ids are Terraform variables with the verification command in
their descriptions, so the failure is a one-line change rather than a hunt.

Prompt caching still applies (a `cachePoint` after the system block). Below the model's minimum
cacheable length Bedrock ignores the marker rather than erroring, which is the right failure mode
for a corpus this small.

---

### 50. Cache repeated answers, by exact match only (2026-08-31)
A portfolio assistant is asked the same opening questions endlessly — certifications, remote work,
"what has he built". Those replies are now cached in DynamoDB, so a repeat costs nothing and
returns in ~20ms instead of ~2s. The latency is the bigger win; the reader notices it, the bill
does not.

**Exact match after normalisation, not semantic similarity.** Embedding each question to find a
"close enough" cached answer would reintroduce exactly the retrieval machinery ADR-0004 declined,
add a model call to save a model call, and carry a failure mode plain matching does not have: a
near-miss returning the answer to a *different* question, confidently. Normalisation handles case,
whitespace and trailing punctuation; genuine paraphrases miss and pay for a model call, which is
the correct outcome.

Two conditions make it safe, and both are load-bearing:
- **First questions only.** "What about the second one?" is meaningless without the turns before
  it. Caching a context-dependent reply would serve it to someone whose context differs — same
  words, wrong answer.
- **The corpus fingerprint is part of the key**, hashed over the corpus *content* with
  `generatedAt` excluded. Content changes → every old answer becomes unreachable rather than
  stale; a rebuild that changed nothing keeps the cache warm. A cached "he holds three
  certifications" outliving a fourth is precisely the drift the build-time corpus exists to stop.

The rate-limit table absorbed this rather than a second table being added — both row kinds are
hashes that expire by TTL, and one table means one resource, one IAM statement, one thing to
reason about. Renamed `-chat-rate-limit` to `-chat-state`, which is free because none of M5 has
been applied yet.

The write is **awaited, not fired and forgotten**: Lambda freezes the container the moment the
response returns, so a pending write would be suspended mid-flight and might never land — a cache
that silently never fills. A few milliseconds on a miss buys a cache that actually works.

Cache hits still consume a rate-limit slot. They cost nothing in model spend, so exempting them
would be friendlier — but it would also make cached questions an unbounded free invocation path.
The limit is about total abuse, not only model cost.

---

### 51. Third design revision — interactive minimalism (2026-08-31)
Luis directed a major frontend pass with Bryl Lim's portfolio as reference: minimalist but
entertaining. Two earlier calls are knowingly reversed, on the record:
- **The chatbot is now a floating robot** (bottom-right, waves on a long loop, greets once per
  session) — reversing #48's "not a floating bubble". The mitigations moved rather than vanished:
  the icon is unmistakably a robot, and the AI disclaimer still leads the dialog. The icon is
  hand-drawn SVG in the site's own hairline-and-accent vocabulary, not a scraped asset with a
  licence to check and a style that almost matches.
- **The top bar is deleted** — the last of #16's WordPad chrome. Everything it held has a better
  home: résumé in the sidebar foot AND a new Contact row (so phones keep the download), theme
  control in the sidebar and status bar, view-source covered by the status bar's commit link.

The rest, as built:
- **Certifications are a fading carousel** of the official Credly emblems with per-cert
  verification links — the design goal is proof, not decoration. Cards crossfade; a swipe sets
  the spin direction and the auto-advance keeps it. Issued/expiry dates render when present in
  profile.ts and are omitted, never invented, when absent.
- **Theme control is a three-position wheel** — light · system · dark — with a sliding knob;
  "system" is a first-class position, not a buried reset. Theme changes cross-fade the page
  (View Transitions where available, a one-beat colour transition elsewhere). One state module
  (scripts/theme.ts) drives both the wheel and the status bar's compact mobile button.
- **Every external link opens a new tab** (`rel="noopener noreferrer"` throughout); internal
  navigation stays same-tab, because new-tab within a site is an anti-pattern.
- **Scroll animations replay on back/forward.** The back/forward cache restores the page with the
  reveal classes already applied; `pageshow` + `persisted` is the signal a restore happened, and
  the classes are stripped and re-observed.
- **Hybrid re-skin**: serif body stays (the identity), a faint dotted-grid ground arrives
  (radial-gradient, far below contrast thresholds), plus hover micro-interactions — underlines
  that draw in, projects that lift with an accent edge, sidebar numbers that nudge.
- **The photo is Bayer-dithered by default and becomes the real photograph on hover/tap.** The
  dither is generated black-on-transparent and applied as a CSS mask over an ink-coloured layer,
  so one PNG follows both themes. Dithered at 180px and upscaled nearest-neighbour — full-res
  dither is grey mush, chunky dots are the look. It is also a quiet nod to the ASCII portrait
  this photo replaced.

Everything animated is transform/opacity, gated on hover-capable devices where it is decorative,
and silenced wholesale by the existing reduced-motion rule.

**Why:** the site read as finished but static. The reference proves restraint and playfulness are
not opposites — the trick is that every animation is information (a wave says "I am here", a knob
says "three states", a lift says "clickable") rather than decoration.

---

### 52. The assistant opens as a chat head, not a modal (2026-08-31)
The panel was a centred `showModal()` dialog over a dimmed page. Luis's reference is Messenger on
Android: tap the bubble, a small box grows out of it and stays attached to it. That is what ships
now — the panel is anchored above the robot, scales out of its bottom-right corner, and the page
behind stays lit and scrollable.

**The modal was wrong for what this bot is for.** Almost every question it gets is about something
already on the page — a certification, a project, how the deploy works — so blacking out that page
to ask about it makes the reader close the assistant to go and look, losing the thread. A
non-modal panel lets them read the answer and the section it refers to at the same time.

The cost is real and paid explicitly: `show()` gives none of what `showModal()` gave for free, so
Escape, tap-away-to-dismiss and returning focus to the robot are hand-written in ChatDialog's
script. **Focus trapping is deliberately not re-implemented** — a non-modal popup that will not let
the keyboard leave is a worse bug than the one it would fix, and the panel sits last in the DOM so
tabbing past it lands somewhere sensible.

Details that carry weight:
- **The corner is three tokens** (`--launcher-inset-x/-y`, `--launcher-size`) in tokens.css, read
  by both components. The panel measures its own height budget by subtracting the robot's size, so
  a launcher that shrinks on phones without the panel knowing would push the panel off-screen. Two
  files agreeing by construction rather than by memory — the same rule as #25 and sections.ts.
- **The robot is a toggle** and carries `aria-expanded`, which is what a chat head does and what a
  disclosure control owes a screen reader. Its wave stops while the panel is open: a hand flapping
  next to a conversation the reader is already in reads as an unread notification.
- **Tapping away is safe because closing costs nothing.** The transcript and any half-typed
  question survive, so the dismissal gesture Messenger trains people into cannot lose work here.
  Focus only returns to the robot if focus was inside the panel — closing because the reader
  clicked something else must not yank the caret out of whatever they clicked.
- **The exit animation needs `transition-behavior: allow-discrete`**, written as its own longhand
  rather than inside the `transition` shorthand. An engine that does not know the keyword drops one
  declaration and loses the shrink-away; putting it in the shorthand would invalidate that entry
  and lose the fade with it. `@starting-style` supplies the frame to animate *from*, which an
  element arriving from `display: none` otherwise does not have.
- **`overscroll-behavior: contain` on the transcript.** The page behind is no longer inert, so a
  flick that hits the end of the log would otherwise scroll the document out from under the reader.
- The composer's "Send" became a round arrow key: at 23rem the word cost a third of the row, and
  the arrow is the shape every messenger has already taught people to look for.

**Why the greeting card now retires on an event rather than on a click:** it occupies exactly the
spot the panel opens into. It used to be dismissed by watching for clicks on the robot, which
missed Alt+K and the suggestion buttons — both open the panel without one, and both left the card
stranded underneath it. ChatDialog announces `chat:open` instead, so every route in closes it.

---

### 53. What it actually took to make the assistant answer (2026-08-31)
Bedrock model access came through, and the assistant still returned this site's 404 page for every
question. Two separate faults, both in the CloudFront→Lambda hop, both invisible from either end.

**Fault 1 — the permission that authorises the URL is not the permission that authorises the
function.** `aws_lambda_permission` granted `lambda:InvokeFunctionUrl` and nothing else. AWS
requires **two** statements for an OAC-signed function URL: `InvokeFunctionUrl` for the URL, and
`InvokeFunction` for running the function behind it. With only the first, the Lambda service
rejects every signed request with 403 *before the handler runs*.

**Fault 2 — Lambda does not accept unsigned payloads.** With OAC in front of a function URL,
CloudFront signs each origin request with SigV4 and folds the caller's `x-amz-content-sha256`
into that signature. A POST that does not carry the SHA-256 of its own body is rejected 403. So
the browser has to hash the body it is about to send — this is a requirement of the origin
architecture, not a CloudFront nicety, and it belongs in the fetch call next to the body it
describes.

**Why this took so long to see, and the lesson worth keeping:** `custom_error_response` maps 403
*and* 404 to `/404.html` for the whole distribution, including `/api/*`. So an authorisation
failure at the origin arrived as this site's own 404 page, served from S3, complete with
`Server: AmazonS3` — which reads exactly like "CloudFront never matched the API behaviour and fell
through to the bucket." It was not that. The thing that finally separated the two was the
function-URL metrics: **`UrlRequestCount` 9, `Url4xxCount` 9, `Invocations` 0**. Requests were
arriving and being refused at the door. A rejection before invocation writes nothing to the
function's log group, which is why the logs looked like no traffic at all.

Diagnostic order that worked, kept because it generalises: invoke the function directly (handler,
Bedrock, corpus, DynamoDB all fine) → sign a request to the function URL by hand (200, so the URL
and its auth are fine) → prove which cache behaviour matched by requesting the API path on `www`,
where the router function's apex redirect would fire if the *default* behaviour had matched (it
did not redirect, so `/api/*` matched) → conclude the fault is in the hop itself, and read the
metrics rather than the logs.

**A green pipeline never caught this**, and that is the uncomfortable part. `lambda.yml` ran once,
on 2026-08-30, and failed — the code uploaded, the smoke test did not pass, and the failure was
read as the Bedrock verification still being in progress. It was two other things as well. The
smoke test now sends the payload hash like the browser does, so it exercises the real path
instead of a path no client uses. Same principle as the gate that never ran: a check that cannot
pass for the right reason teaches you to explain away its failure.

---

### 54. Messenger's shape, this site's palette (2026-08-31)
Luis asked for the Facebook Messenger chat design — AI left, reader right. The left/right split
already existed since #52; what was missing was everything that makes a thread read as a thread.
**Messenger's structure was adopted and its palette was declined**, and the split is the decision
worth recording.

**Taken:** 18px pill bubbles, grouped stacks, an avatar on the incoming side, three bouncing dots
for typing, a system sans inside the panel, ~78% bubble width, 2px gaps inside a group against a
real gap when the speaker changes.

**Declined:** `#0084FF` and `#F0F0F0`. tokens.css opens by forbidding raw colour literals
downstream and records a measured contrast ratio for every ink/surface pair. Two hardcoded
Messenger colours would have meant inventing dark-mode variants for them and hand-checking two new
pairs, to make a portfolio look like someone else's product. Outgoing bubbles use `--color-accent`,
incoming use `--color-chrome`, both as **aliases** — so dark mode and contrast were already solved
before the first bubble was drawn.

`--radius-bubble: 1.125rem` knowingly contradicts "radii stay near-square" four lines above it in
the same file. That rule is about *chrome* — title bars, buttons, the status bar. A chat bubble is
not chrome, and a 2px message bubble does not read as a message.

**Grouping is CSS, not state.** The whole stack effect — squared inner corners, the avatar showing
only on the last bubble of a run — falls out of sibling order through `:has(+ .row--in)`. The
script does not know or care who spoke last; it appends a row and the stylesheet works out the
shape. Nothing to keep in sync, and nothing to get wrong when a message is removed (which the
typing indicator does on every single turn).

**The bug this uncovered, which is the part worth remembering.** Astro scopes a component's CSS by
stamping `data-astro-cid-*` onto elements *it* renders, and every selector in the block carries
that attribute. Every message here was built with `document.createElement`, so **no bubble the
script produced had ever matched a single rule** — they were unstyled paragraphs. It went unnoticed
because only the hand-written opening message was server-rendered, and because #53 means no answer
has ever actually reached the panel in a browser. The fix is to clone `<template>`s that Astro has
already stamped, which needs no knowledge of how Astro names that attribute. The opening message
now renders through that same path instead of existing twice in two forms, so the log ships empty
and there is exactly one way a bubble can come into being.

The typing dots carry a `visually-hidden` "Thinking…". The log is `aria-live`, and three animated
dots announce nothing at all to someone listening rather than looking.

---

### 55. The apply role could not read what it had never been asked to write (2026-08-31)
The first CI apply after #53 failed during **plan**, not apply:
`AccessDeniedException ... dynamodb:DescribeTable`, and the same for
`logs:DescribeLogGroups`. The `joaqs-online-infra-apply` policy was written in M4 for the
resources that existed then — S3, CloudFront, ACM, Budgets, SNS, IAM — and M5 added Lambda,
DynamoDB and a log group without extending it.

**Why it stayed invisible until now:** M5 was applied from a laptop holding AdministratorAccess,
so the apply role was never once exercised against those resources. The pipeline looked healthy
because nothing had asked it to do the thing it could not do. Meanwhile the *plan* role carries
`ReadOnlyAccess`, so pull-request plans passed throughout — the failure could only ever surface on
an approved apply, which is the least convenient place to find it.

**The failure was a read.** A plan refreshes every resource in state, so a role that cannot read a
resource cannot plan it, let alone change it. Least-privilege on a Terraform role is therefore not
"what may this change" but "what may this *see*", and the second list is always longer. Adding a
service to this configuration means adding it to that role in the same commit.

Added: `lambda:*` on `function:joaqs-online-*`, `dynamodb:*` on `table/joaqs-online-*`, log-group
management on `/aws/lambda/joaqs-online-*` (both ARN forms — AWS matches the bare name for some
actions and the `:*` suffix for others), `logs:DescribeLogGroups` on `*` because a list call is
evaluated against no single group, and **`iam:PassRole`** on the existing project-role prefix,
which `CreateFunction` needs to hand the function its execution role and which nothing had
required before M5.

**Breaking the circle.** The role that applies the fix is the role the fix repairs, and it could
not complete a plan to get there. Resolved with one targeted apply from a laptop —
`terraform apply -target=module.cicd.aws_iam_role_policy.infra_apply` — which touches exactly one
resource and leaves every real infrastructure change to go through the Environment approval in
`infra.yml`. Targeting is the documented escape hatch for precisely this, and Terraform says so in
its own warning. Note that the target still pulls `module.site` and `module.chatbot` in as
dependencies to resolve `chat_function_arn`, so it has to run as a principal that can read them —
which is the whole point, and why it cannot be done by the broken role itself.

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
- [x] Tune the ASCII portrait locally and commit the `.txt` (#44) — done 2026-08-30,
      `scripts/portrait/generate.mjs`
