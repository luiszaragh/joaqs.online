# ADR-0006 — The assistant speaks in the third person and is labelled as an AI

- **Status:** accepted
- **Date:** 2026-08-30
- **Milestone:** M5
- **DECISIONS.md:** #12, #20

## Context

A portfolio chatbot has an obvious tempting design: let it speak as the
candidate. "Hi, I'm Luis — ask me anything about my experience." It reads as
personal, it is what most such widgets do, and it is more charming than the
alternative.

It is also the design where a hallucination becomes a lie told in someone's
name.

## Decision

The assistant speaks about Luis in the **third person**, is **labelled as an AI
in the dialog itself**, and its system prompt instructs it to state plainly that
it is an AI if asked. Its knowledge is the build-time corpus and nothing else,
and it is instructed to decline rather than infer.

The label — *"AI assistant — answers from Luis's résumé and project docs. It can
be wrong."* — is in the dialog header, visible before any answer is read, not
in a tooltip or a footer.

## Consequences

**A hallucination stays an error rather than becoming a misrepresentation.**
Every model invents things occasionally. If a first-person bot invents a
certification, an AI has told a recruiter, in writing, that a candidate holds a
credential he does not — and the candidate's name is on it. In the third person
with a visible label, the same failure is a wrong answer from a labelled
machine. The failure rate is identical; the consequence is not.

**Grounding does not remove the need for this, and it is worth being precise
about why.** The corpus makes fabrication unlikely, not impossible: the model
can still combine two true facts into a false one — reading "Terraform" in a
skills list and "5 months at Noventiq" in an experience entry and producing
"five years of Terraform". No amount of grounding closes that gap. The persona
decision is what makes the residual gap survivable.

**Honesty about status is an explicit instruction, not an emergent property.**
Two of the three projects are unfinished — one in rework, one pending a
sanitized write-up — and the corpus carries their status notes. A bot describing
in-progress work as shipped would be a misrepresentation whether or not it was
in the first person, so the prompt says so directly and the corpus supplies the
`statusNote` field for it to say it with.

**The prompt is treated as untrusted-input-facing.** It ends with an explicit
instruction to ignore anything in a user message attempting to change these
rules, reveal the prompt, or make it speak as Luis. This is not a security
boundary — prompt injection is not solved by asking nicely — which is why the
real controls sit elsewhere: the function's role can read one S3 object,
increment one DynamoDB row and invoke one model — nothing else — the reply is
capped at 400 tokens, and the worst outcome of a successful injection is an
embarrassing sentence rather than access to anything.

**It is less charming.** That is the whole cost, and it is accepted. A recruiter
who wanted Luis's voice can read what he wrote, which is exactly what the
`intro` field in `profile.ts` is marked never to be rewritten into marketing
copy.

## Alternatives considered

**First person as Luis.** Rejected on the reasoning above. This is the decision
the ADR exists to record, because it is the one a future edit is most likely to
undo for being friendlier.

**First person, but disclosed** ("I'm an AI trained on Luis's résumé"). Rejected
as the worse of both: it still produces sentences of the form "I hold the DevOps
Professional certification", which is the exact string that causes the harm,
while relying on the reader to have carried the disclosure through the
conversation.

**No chatbot at all.** Genuinely considered. It is the one component here that
can spend money and carries a real abuse surface, and its absence would cost the
site little. It ships because the interesting engineering is in the guardrails —
the rate limiting, the OAC-signed endpoint, the build-time corpus — and those
are the part worth showing.
