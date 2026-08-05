---
name: model-selection-advisor
description: Recommend which Cursor model to use for tasks in this repo, balancing cost against performance, backed by current benchmark data. Use when the user asks which model to pick for a task, wants a model cost/performance breakdown, or asks to refresh model recommendations from CursorBench / Artificial Analysis data.
disable-model-invocation: true
---

# Model Selection Advisor

Produce an executive-style recommendation of which Cursor models to use for which
tasks in this repository, balancing cost efficiency against performance. Output must
be digestible in under a minute and immediately actionable.

## Inputs

1. **CursorBench data** — the current leaderboard at https://cursor.com/evals
   (per-model score, cost/task, tokens/task, steps/task).
2. **Artificial Analysis data** — https://artificialanalysis.ai/, especially:
   - Intelligence Index (`/evaluations/artificial-analysis-intelligence-index`)
   - AA-Omniscience (`/evaluations/omniscience`) for accuracy + **hallucination rate**.

The user may paste/upload this data. If data is stale or missing, fetch it with web
search/fetch. **Constrain the model universe to models listed on the CursorBench page.**

## Process

1. **Gather data.** Read supplied CursorBench + AA data; fetch anything missing. Note
   the read date (benchmarks change fast).
2. **Filter** to models available on the CursorBench page.
3. **Score per axis:**
   - Coding tasks → weight CursorBench score and cost/task; watch steps/tokens
     (chatty models cost more in round-trips).
   - Reasoning/knowledge tasks (architecture, compliance) → weight AA Intelligence
     Index, and **heavily weight AA-Omniscience hallucination rate** — a model that
     fabricates a standard's clause is dangerous even if "accurate" overall.
4. **Apply caveats:** flag known benchmark artifacts (e.g. training-data
   contamination), and prefer efficiency (fewer retries) for tasks where a wrong edit
   is cheap to catch vs. expensive to miss.
5. **Map to the four categories below**, picking a primary + fallback per category.
6. **Keep it brief.** Executive report. Lead with the picks; back each with numbers.

## Repo context (why this matters here)

This is a Django LIMS/data API in a regulated (medical-device) domain: models,
migrations, permissions, feature flags, TRS integration state logic. Most coding is
convention-following pattern work, not frontier reasoning — so raw model IQ rarely
pays off for code. The exception is regulatory/architecture work (ISO 62304, ISO
27001, 21 CFR Part 11), where **calibration/hallucination matters more than raw
knowledge** and paying up for reasoning is justified.

## Output format

Lead with a one-line TL;DR, then a single markdown table covering the four
categories (one row per category). After the table, add brief notes only where a
workflow or caveat matters (e.g. the compliance cross-check + human-verification
rule), then cite sources and the read date.

Use this table structure:

```
TL;DR: <one sentence rule-of-thumb across the four categories>

| Category | Primary pick | Fallback / cross-check | Backing data |
|---|---|---|---|
| Architecture / Compliance (standards → requirements/design; citation-sensitive) | <model> | <different family> + <knowledge amplifier> | Intelligence Index, Omniscience Index, accuracy %, **hallucination %**, ~$/task |
| Complex coding + derived compliance impl (multi-file refactors, tricky debugging) | <model> | <different family> → <break-glass> | CursorBench score, ~$/task, steps |
| Daily coding (bugfixes, small features, tests, migrations) | <best-value model> | <cheaper high-volume alt> | CursorBench score, ~$/task |
| Routine / trivial coding (typos, comments, renames, formatting) | <cheapest capable model> | — | CursorBench score, ~$/task |

Notes:
- Compliance: primary = best-*calibrated* model (reviewer); use the knowledge
  amplifier only for anchor docs and treat its confident claims as unverified.
  A human MUST verify every standard/clause citation regardless of model.
- <any repo-specific caveat, e.g. don't drop below Composer-class on this codebase>

Sources: CursorBench (<url>), AA (<urls>). Read <date>.
```

## Reconciled baseline (as of 2026-07-13)

Starting point derived from CursorBench 3.2 + AA v4.1, reconciled across multiple
model runs. **Re-verify the numbers on each run** — treat this as the prior, not
gospel. Key verified figures: Fable 5 accuracy 61% / Omniscience Index 40 but
**hallucination ~55%**; Opus 4.8 accuracy 46.6% / Index 27 / **hallucination 35.9%**
(lowest of frontier, by abstaining); Sol Max CursorBench ~67% @ ~$5.69.

| Category                                 | Primary                                 | Fallback / cross-check                                        | Backing data                                                                                                  |
| ---------------------------------------- | --------------------------------------- | ------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| Architecture / Compliance                | Opus 4.8 Max (best-calibrated reviewer) | Fable 5 Max = knowledge amplifier for anchor docs only        | Opus: Idx 56, Omni 27, acc 46.6%, halluc 35.9%, ~$5.77. Fable: Idx 60, Omni 40, acc 61%, halluc ~55%, ~$17.32 |
| Complex coding + derived compliance impl | Sol Max                                 | Opus 4.8 Max (diff family) → Fable 5 Extra High (break-glass) | Sol ~67% @ $5.69; Opus 62.3% @ $5.77; Fable XHigh 68.4% @ $11.73                                              |
| Daily coding                             | Sol Medium                              | Terra XHigh ($1.44) / Luna High ($0.82)                       | Sol Med 60% @ $1.95                                                                                           |
| Routine / trivial coding                 | Composer 2.5                            | —                                                             | 56.1% @ $0.44                                                                                                 |

Rationale worth preserving:

- **Compliance = calibration over coverage.** A confidently-wrong clause slips past a
  human reviewer; an abstention doesn't. Opus's lower hallucination rate (36% vs
  Fable's 55%) makes it the safer _primary_, even though Fable tops the composite
  Omniscience Index by answering more. Sol interprets _nothing_ in the standards — it
  only translates already-approved requirements into code/sub-docs.
- **Don't drop below Composer-class on this repo.** Ultra-cheap tiers (e.g. Luna Low
  37.6%) will botch even "trivial" edits amid migrations/permissions/state logic; the
  few-cent saving isn't worth a wrong edit here.
- **Exclude Grok** despite strong value (training-data contamination flagged by Cursor).
- **Daily driver is a middle-rung call:** Sol Medium is the value knee; go cheaper
  (Terra/Luna) only for high volume where a few points don't matter, pricier (Sol High)
  only when round-trips are costly.

## Guidance for the picks

- **Cost/performance is the spine.** Don't recommend a top-tier model for cheap work,
  or a cheap model where a wrong answer is expensive (compliance, one-shot planning).
- **Reserve the highest-cost model (e.g. Fable-class)** as break-glass for coding, but
  treat it as genuinely justified for anchor compliance/architecture docs (it tends to
  top both Intelligence and Omniscience).
- **Distinguish accuracy from hallucination.** For compliance, a knowledgeable but
  overconfident model is a liability; prefer one that abstains ("I don't know").
- **Always** include the human-verification caveat for regulatory citations.
- Cite the source pages (CursorBench + AA) and the read date.

## Anti-patterns

- Don't recommend models not on the CursorBench page.
- Don't present stale numbers without noting the read date.
- Don't bury the recommendation under methodology — picks first, evidence second.
- Don't exceed four categories.
