# ADR-0004 — Stuff the whole corpus into the prompt; no RAG, no vector database

- **Status:** accepted
- **Date:** 2026-08-30
- **Milestone:** M5
- **DECISIONS.md:** #11, #20, #29, #33

## Context

The chatbot answers questions about one person from a fixed, small body of
material: a résumé, a handful of projects, some blog posts, and facts about
this site. The total is about 5 kB of JSON — roughly 1,500 tokens.

The default architecture for "answer questions from documents" is retrieval-
augmented generation: embed the documents, store the vectors, embed the
question at request time, retrieve the nearest chunks, and put only those in
the prompt. It is the pattern every tutorial reaches for.

## Decision

**Put the entire corpus in the system prompt on every request, and cache it.**
No embeddings, no vector store, no retrieval step.

The corpus is generated at build time from the site's own data files
(`scripts/corpus/build.mjs`), published to S3 by the site deploy, and fetched
by the Lambda on cold start into module scope.

## Consequences

**Retrieval cannot fail, because there is none.** The most common RAG failure
is the retriever returning the wrong chunks, at which point a capable model
answers confidently from irrelevant context. Here the model sees everything
every time. If the answer exists in the material, it is in the prompt.

**Prompt caching makes the cost argument collapse.** The system prompt is
byte-identical on every request, so it is marked `cache_control: ephemeral`.
Cache reads are a fraction of the input token price. The economics that
motivate RAG — "don't pay to send 100k tokens every call" — do not apply to
1,500 cached ones.

**The infrastructure that does not exist cannot break.** No vector database to
run, secure, back up, or pay for. No embedding model to version. No chunking
strategy, and therefore no chunk-boundary bug where a certification's name and
its status land in different chunks. The retrieval step's entire failure surface
is absent.

**Drift is impossible by construction.** The corpus is built from
`site/src/data/profile.ts` and `posts.ts` — the same files the page renders
from — as a `prebuild` script, so it regenerates on every build whether or not
anyone remembers. The bot cannot claim a certification the page does not show,
and cannot miss a project that shipped an hour ago. With a separately-maintained
vector store, keeping them in sync would be a recurring chore that fails
silently.

**This decision has a clear expiry condition, and it is enforced.** Context
stuffing stops being right when the corpus outgrows the prompt. The build script
fails the build above 120 kB with a message pointing back at this ADR. That is
deliberate: the failure mode of a good decision is that it is kept past the
point where it was true, so the boundary is a gate rather than a comment.

**The honest counter-argument.** Building RAG here would demonstrate familiarity
with a pattern interviewers ask about, and this site exists partly to be
evidence of skill. That is résumé-driven development, and an interviewer who
knows the space reads it as the opposite of what it intends — someone who
reaches for machinery before checking whether the problem needs it. The
defensible version of the skill is knowing where the line sits, which is what
this document is.

## Alternatives considered

**RAG with a managed vector store** (OpenSearch Serverless, Pinecone).
Rejected: OpenSearch Serverless starts near $175/month; a hosted vector database
is a monthly bill and a second system of record. For six documents.

**RAG with embeddings in DynamoDB**, brute-force cosine similarity in the
Lambda. Rejected: cheap, but it is retrieval machinery for a corpus that fits in
the prompt whole. It would add the chunking and ranking failure modes while
saving roughly 1,200 cached tokens per call.

**Fine-tuning a model on the résumé.** Rejected: worse on every axis. Facts
would live in weights instead of a file, updating one would mean retraining, and
a fine-tuned model still hallucinates — it just does so in a more convincing
register.
