# Research Agent: Phased Implementation Plan

## Overview

This document translates the high-level improvement plan into a concrete,
phase-by-phase execution guide. Each phase lists the exact files to change,
what currently exists, what replaces it, and a done-checklist to verify
completion.

File inventory:

- `agents/research.md` - orchestrator (280 lines)
- `agents/research-searcher.md` - discovery subagent (88 lines)
- `agents/research-fetcher.md` - extraction subagent (67 lines)
- `agents/research-analyst.md` - synthesis subagent (54 lines)
- `agents/research-critic.md` - adversarial review subagent (82 lines)
- `agents/research-writer.md` - drafting subagent (53 lines)
- `agents/research-verifier.md` - does not exist yet (created in Phase 2)

## Phase 0 - Cleanup & Alignment

Goal: Fix internal inconsistencies, policy mismatches, and brittleness in
existing files. No behavioral changes. No new phases or agents. This is purely
preparation - it makes each file internally consistent and removes known failure
modes before anything structural is added.

Rationale: The files have several cases where the machine-readable policy
(frontmatter) and the natural-language rules (prompt body) contradict each
other, or where rules have edge cases that cause unnecessary failures. All of
these should be resolved before adding new complexity.

### File: `agents/research.md`

#### Change 0.1 - Fix the `grep` policy mismatch

Problem: Line 14 in the frontmatter allows `grep`. But lines 49-50 in the
prompt body list the only pre-approval tools as `question`, `todowrite`,
`todoread`, `read`, `glob`, and `list` - `grep` is absent. This means the model
can be confused about whether `grep` is allowed before plan approval.

Current text:

```text
approval are `question`, `todowrite`, `todoread`, `read`, `glob`, and `list`.
```

Replace with:

```text
approval are `question`, `todowrite`, `todoread`, `read`, `glob`, `list`, and `grep`.
```

Why `grep` stays allowed: Local repo exploration (e.g., finding config files,
understanding codebase structure) can legitimately inform a research plan
before any browsing happens. Keeping it pre-approval is correct.

#### Change 0.2 - Fix the `Research State` block heading

Problem: The `Research State` format is plain unformatted text with no markdown
heading. In a long research session rendered in a TUI, this is harder to scan.

Current text:

```text
### Research State block (keep short)
Use this exact format:
Research State
- Phase:
- Completed:
- In progress:
- Next:
- Open questions:
```

Replace with:

```text
### Research State block (keep short)
Use this exact format (max 5 lines total):
### Research State
- Phase:
- Completed:
- In progress:
- Next:
- Open questions:
```

The `max 5 lines total` constraint is added here because it is a formatting and
output quality fix, not a behavioral change.

#### Change 0.3 - Remove the batching clause

Problem: `research.md` currently says to delegate to `research-searcher` per
workstream "or batch if small." The `research-searcher` output contract is
explicitly scoped to one workstream, so batching multiple workstreams into one
invocation creates a format conflict and inconsistent output.

Current text:

```text
- Delegate to `research-searcher` per workstream (or batch if small).
```

Replace with:

```text
- Delegate to `research-searcher` per workstream. Always one invocation per workstream. When workstreams are independent, invoke them in parallel.
```

### File: `agents/research-searcher.md`

#### Change 0.4 - Split `Query set` into `Search strategy` and `Searches performed`

Problem: The current `Query set` mixes planned queries with executed queries.
That weakens auditability. The file already has a separate `Searches performed`
section that tracks actual tool calls, but section 2 remains ambiguous.

Current text:

```text
2) Query set
- 5-12 search queries you used or would use (include synonyms and opposing terms).
```

Replace with:

```text
2) Search strategy
- 3-6 query directions or query families you planned to pursue, with a one-line reason for each.
- This is your search intent, not a list of executed queries.
```

The existing `5) Searches performed` section stays unchanged.

### File: `agents/research-fetcher.md`

#### Change 0.5 - Redefine `ACCESS_ERROR` threshold

Problem: The current `ACCESS_ERROR` rule triggers when a page returns fewer than
3 extractable facts. Some very short but authoritative pages contain only 1-2
facts and are still high-value. This rule silently discards them.

Current text:

```text
- If a URL returns a paywall, login wall, or insufficient content (fewer than
  3 extractable facts), return for that source:
  ACCESS_ERROR: <URL> - <reason: paywall / login required / empty content>
```

Replace with:

```text
- If a URL returns a paywall, login wall, or content so sparse that no
  domain-relevant facts can be recovered, return for that source:
  ACCESS_ERROR: <URL> - <reason: paywall / login required / empty content>
- Short but useful sources (1-2 facts) should be extracted normally and tagged
  in Caveats / limitations with: "brief source; limited detail"
```

### File: `agents/research-analyst.md`

#### Change 0.6 - Add uncertainty-type precedence order

Problem: The three uncertainty prefixes exist but there is no guidance on which
to use when a claim could qualify for more than one. This leads to inconsistent
analyst outputs and complicates orchestrator handling.

Current text:

```text
- Prefix each bullet with one typed state:
  - CONFLICTING_EVIDENCE:
  - INSUFFICIENT_PRIMARY_SOURCE:
  - UNVERIFIED_HIGH_RISK:
- Use UNVERIFIED_HIGH_RISK for unresolved security-sensitive claims (e.g., CVE,
  exploitability, affected/patched versions) until primary-source verification exists.
```

Replace with:

```text
- Prefix each bullet with one typed state. Use the highest applicable in this order:
  1. UNVERIFIED_HIGH_RISK - security-sensitive or materially risky claims (CVE,
     exploitability, affected/patched versions); takes precedence over all others.
  2. CONFLICTING_EVIDENCE - sources materially disagree and no high-risk rule applies.
  3. INSUFFICIENT_PRIMARY_SOURCE - evidence is not contradicted but remains too
     weakly sourced; use only when neither above applies.
```

### File: `agents/research-critic.md`

#### Change 0.7 - Replace forced-minimum-bullet with explicit certification

Problem: The critic is framed as needing at least one weakness bullet, which can
encourage performative skepticism. The better pattern is explicit certification
when no real weakness exists.

Current text:

```text
Weak claims / needs stronger sourcing (minimum 1 bullet required)
- If no claims are weak, write: "No weak claims identified - all major claims
  have strong primary source support." This counts as the required bullet.
- Otherwise, for each weak claim include: the claim text, why it is weak,
  and what source type would strengthen it.
```

Replace with:

```text
Weak claims / needs stronger sourcing
- If all major findings have primary source support and no material weaknesses
  exist, write exactly:
  CLAIMS CERTIFIED: all major findings have primary source support with no
  material weaknesses identified.
- Otherwise, for each weak claim include: the claim text, why it is weak,
  and what source type would strengthen it.
```

### Phase 0 Done-Checklist

- [ ] `research.md`: `grep` added to pre-approval tool list
- [ ] `research.md`: `### Research State` heading + `max 5 lines` constraint
- [ ] `research.md`: batching clause removed; parallel invocation added
- [ ] `research-searcher.md`: `Query set` renamed to `Search strategy`
- [ ] `research-fetcher.md`: `ACCESS_ERROR` threshold replaced; short-source caveat added
- [ ] `research-analyst.md`: precedence order added to uncertainty prefixes
- [ ] `research-critic.md`: `CLAIMS CERTIFIED` replaces forced minimum bullet

## Phase 1 - Orchestrator Structural Improvements

Goal: Improve the orchestrator's control logic: intake discipline, planning
quality, interruption policy, evidence alignment gate, Phase 7 replacement, and
writer handoff. All changes are in `research.md` only.

Rationale: These changes make the orchestrator's decision-making more
deterministic and reduce unnecessary user interruptions and process overhead.
They do not require the verifier to exist yet, and they do not depend on
subagent output format changes. Getting the orchestrator right first means later
phases land into a cleaner host.

### File: `agents/research.md`

#### Change 1.1 - Reduce Phase 0 intake to max 3 questions

Problem: The current file allows 3-7 intake questions. Seven questions is too
many for most sessions and signals poor question design. Three well-chosen
questions covering objective, scope, and output shape are sufficient.

Current text:

```text
- Otherwise, use the `question` tool to ask the minimum number of questions needed (3-7).
```

Replace with:

```text
- Otherwise, use the `question` tool to ask at most 3 targeted questions.
  Each question must cover exactly one unknown dimension:
  - Objective or decision being supported (skip if clear from the prompt)
  - Scope, timeframe, or depth (skip if clear from the prompt)
  - Output shape or format (skip if clear from the prompt)
  If all three are clear from the user's prompt, skip questions entirely.
```

#### Change 1.2 - Add workstream definition to Phase 1

Problem: The plan proposal phase gives no guidance on what constitutes a
workstream. This produces uneven workstream quality - some too broad to generate
useful queries, some too narrow to justify their own discovery pass.

Add after the `Workstreams (3-6 bullets)` item:

```text
- Workstream definition: a workstream is a distinct angle of inquiry that
  requires its own discovery pass. Each workstream must be broad enough to
  justify multiple candidate sources and narrow enough to produce actionable
  search queries. If a workstream would only produce a subsection rather than
  a distinct research track, merge it. If a workstream lacks any clear primary
  source path, mark it as exploratory in the plan.
```

#### Change 1.3 - Simplify Phase 2 state initialization

Problem: The file currently instructs the orchestrator to create the Evidence
Table with empty rows. Placeholder rows add ceremony without value - the table
should start as a header scaffold only and be populated with real rows as
sources are found.

Current text:

```text
- Create an Evidence Table scaffold with empty rows.
```

Replace with:

```text
- Create an Evidence Table scaffold (header row only - do not create placeholder rows).
- Initialize the todo list at high-level phase tasks only; expand with workstream
  detail after plan approval.
```

#### Change 1.4 - Add dedicated interruption policy section

Problem: The orchestrator has no consolidated interruption policy. Pause
conditions are scattered, creating inconsistent behavior.

Add a new section after the Non-negotiable rules block:

```text
## Interruption policy
Classify every potential pause condition into one of three categories before deciding to interrupt.

### Mandatory interruption - MUST pause and ask the user
- A critical security contradiction remains unresolved after the allowed critique cycles.
- A subagent fails its format contract twice in a row (see double-failure fallback).
- The research cannot continue without a user value judgment that cannot be inferred from evidence.

### Conditional interruption - MAY pause only if the issue blocks report integrity
- An unresolved non-security contradiction that would prevent drafting.
- A critical evidence gap that cannot be filled with search or fetch.
- A source conflict that materially changes the core conclusion.

### Non-blocking carry-forward - MUST NOT trigger a user pause
- Minor evidence gaps.
- Partially-supported claims (downgrade, do not pause).
- Inconclusive but low-risk secondary disagreements.
- Unresolved supporting detail that does not change the core conclusion.
Carry these forward into the Limitations / uncertainty section of the final report.
```

#### Change 1.5 - Rewrite Evidence Alignment Check as a hard checklist

Problem: The current Evidence Alignment Check is prose and easy to skim past.
It should be a concrete pre-critique gate with explicit pass/fail items.

Current text:

```text
### Evidence Alignment Check (required)
- Ensure every evidence ID referenced by analysts maps to an Evidence Table row.
- If any ID is missing, re-run analyst or fetch missing sources before critique.
```

Replace with:

```text
### Evidence Alignment Check (HARD GATE - required before Phase 6)
Before critique begins, confirm ALL of the following:
1. Every evidence ID used by analysts exists as a row in the Evidence Table.
2. Every analyst-flagged critical or important gap is either resolved or explicitly
   carried forward with a reason.
3. Every `UNVERIFIED_HIGH_RISK` item has source-tier notes in the Evidence Table.
4. No unsupported evidence references remain from any synthesis pass.
If any check fails, resolve it before proceeding to critique.
```

#### Change 1.6 - Replace Phase 7 with a conditional final check

Problem: The current Phase 7 repeats synthesis and critique even when Phase 6
already resolved everything cleanly. That adds cost and prompt length without a
proportionate rigor gain.

Replace the current Phase 7 section with:

```text
### Phase 7 - Conditional Final Check
- If Phase 6 resolved cleanly (no unresolved contradictions, no open caveats): skip
  this phase entirely and proceed to Phase 8.
- If Phase 6 ended with user-approved unresolved caveats or carried-forward
  contradictions, run a narrow final check ONLY on the affected workstreams:
  - One analyst pass for only the affected claims/workstreams.
  - One critic pass for only those unresolved items.
  - Do not re-run the full pipeline.
  - If issues remain after this pass, carry them forward into limitations language.
    Do not add another critique cycle.
```

#### Change 1.7 - Formalize the Writer Handoff Package in Phase 8

Problem: The drafting phase currently sends only a `final outline`, `evidence
table`, and `citation rules` to the writer. This is too vague and produces
inconsistent writer inputs.

Current text:

```text
### Phase 8 - Drafting (delegate)
- Delegate to `research-writer` with:
  - final outline
  - evidence table
  - citation rules
- Optionally do minimal spot-check fetches via `exa_crawling_exa` ONLY if needed for critical claims.
```

Replace with:

```text
### Phase 8 - Drafting (delegate)
Before delegating to `research-writer`, prepare a Writer Handoff Package containing:
1. Final outline with section-to-evidence-ID mapping.
2. Complete current Evidence Table.
3. Resolved contradictions summary (what was found and how it was resolved).
4. Unresolved items list with required limitations language for each.
5. Confidence level of key findings where analyst strength tags are available.
6. Citation density expectation (e.g., "every non-obvious claim needs a citation").
Then delegate to `research-writer` with the full handoff package.
- Optionally do minimal spot-check fetches via `exa_crawling_exa` ONLY if needed for critical claims.
```

### Phase 1 Done-Checklist

- [ ] `research.md`: Phase 0 intake capped at 3 questions with dimension guidance
- [ ] `research.md`: Phase 1 workstream definition added
- [ ] `research.md`: Phase 2 Evidence Table starts as header-only scaffold
- [ ] `research.md`: Interruption policy section added
- [ ] `research.md`: Evidence Alignment Check rewritten as 4-item hard checklist
- [ ] `research.md`: Phase 7 replaced with conditional final check
- [ ] `research.md`: Phase 8 Writer Handoff Package defined

## Phase 2 - New `research-verifier` Agent + Orchestrator Integration

Goal: Add the most important structural gap-filler - a dedicated
citation-validation agent that checks whether each claimed finding is actually
supported by the evidence it cites. Wire it into `research.md` as a new Phase 5b
between synthesis and critique.

Rationale: The research identified this as the largest structural gap. The
system can track provenance but cannot currently answer: "Does this specific
claim actually follow from the source it cites?" A dedicated verifier placed
before critique means the critic receives pre-validated claims, improving the
quality of the entire late-stage pipeline.

### New file: `agents/research-verifier.md`

Create this file from scratch with the following content:

```markdown
---
description: Validates that each cited finding is traceable to its stated evidence. Flags unsupported claims and misattributions before critique.
mode: subagent
model: <to be selected - see model review in Phase 4>
steps: 14
permission:
  "*": deny
  exa_crawling_exa: deny
  exa_web_search_exa: deny
  websearch: deny
  webfetch: deny
  read: deny
  grep: deny
  glob: deny
  list: deny
  edit: deny
  bash: deny
---

You are the research-verifier subagent. Your job is narrow and strict: audit whether each analyst finding is actually supported by the evidence it cites.

## Verification status definitions

- `supported`: the cited evidence directly supports the claim as stated.
- `partially-supported`: the main claim is supported but some element overreaches or is not directly stated in the cited source.
- `unsupported`: the cited evidence does not substantiate the claim.
- `misattributed`: the evidence is about something materially different from the claim.

When in doubt, classify as `partially-supported` rather than `supported`. Be conservative.

## Output contract (MANDATORY)
Return ONLY the following sections:

### Claim verification results
For each analyst finding bullet:
- Claim: [exact finding text]
- Evidence IDs cited: [e.g. [1][3]]
- Verification status: supported | partially-supported | unsupported | misattributed
- Rationale: [1-2 lines explaining the verdict]
- Unsupported portion (if any): [what aspect was not supported by the cited evidence]

### Summary
- Total claims reviewed:
- Supported:
- Partially-supported:
- Unsupported:
- Misattributed:

### Escalations
For each unsupported or misattributed claim:
- Claim: [exact text]
- Recommended action: re-fetch source | downgrade to [weak] | remove claim | user-input needed

## Rules
- Do not browse. Do not search. Do not use any tools.
- Work entirely from the Evidence Table and analyst findings provided by the orchestrator.
- Do not propose new evidence.
- Do not rewrite claims. Flag them; the orchestrator resolves them.
- Do not treat absence of verbatim quote as unsupported - assess whether the source plausibly supports the claim from the extracted key points.
- Classify borderline cases as `partially-supported` rather than `supported`.
- Return full structured output even if every claim passes verification.
- If any required section is missing from your output, return ONLY:
  FORMAT_ERROR: missing <section>
```

### File: `agents/research.md` - verifier integration

#### Change 2.1 - Add `research-verifier` to frontmatter task allow-list

Current text:

```text
  task:
    "": deny
    "research-searcher": allow
    "research-fetcher": allow
    "research-analyst": allow
    "research-critic": allow
    "research-writer": allow
```

Replace with:

```text
  task:
    "": deny
    "research-searcher": allow
    "research-fetcher": allow
    "research-analyst": allow
    "research-verifier": allow
    "research-critic": allow
    "research-writer": allow
```

#### Change 2.2 - Add `research-verifier` to the pre-approval subagent list

Current text:

```text
- You MUST NOT invoke any subagent (`research-searcher`, `research-fetcher`,
  `research-analyst`, `research-critic`, or `research-writer`) until the user
  explicitly approves your research plan.
```

Replace with:

```text
- You MUST NOT invoke any subagent (`research-searcher`, `research-fetcher`,
  `research-analyst`, `research-verifier`, `research-critic`, or `research-writer`)
  until the user explicitly approves your research plan.
```

#### Change 2.3 - Add Phase 5b - Citation Verification

Insert after Phase 5 and before critique:

```text
### Phase 5b - Citation Verification (delegate)
- Delegate to `research-verifier` with:
  - all analyst findings from Phase 5 (all workstreams)
  - the current Evidence Table
- Review the verifier's output:
  - `supported` claims: no action needed.
  - `partially-supported` claims: downgrade the finding strength to [weak] before
    passing to critique; note the limitation in Evidence Table notes.
  - `unsupported` claims: resolve before critique - either re-fetch the cited source,
    remove the claim, or escalate to the user if the claim is load-bearing.
  - `misattributed` claims: correct the citation or remove the claim before critique.
- Do not begin Phase 6 while any unsupported or misattributed claim remains unresolved.
- Update todos and Research State.
```

### Phase 2 Done-Checklist

- [ ] `agents/research-verifier.md` created with full frontmatter and rules
- [ ] `research.md` frontmatter: `research-verifier` added to task allow-list
- [ ] `research.md`: `research-verifier` added to subagent enumeration
- [ ] `research.md`: Phase 5b Citation Verification inserted

## Phase 3 - Subagent Contract Improvements

Goal: Strengthen what the four working subagents produce. These changes improve
downstream input quality: the verifier benefits from fetcher verbatim snippets,
the critic benefits from analyst strength tags, and the orchestrator benefits
from clearer gap signals and critic resolution recommendations.

Rationale: Now that the verifier is in place and the orchestrator's control
logic is improved, the subagents' output contracts should be tightened to match.
These changes are additive to the output contract - they extend the format, they
do not break it.

### File: `agents/research-searcher.md`

#### Change 3.1 - Add minimum coverage requirement

Add to the end of the rules section:

```text
### Coverage requirement
- Aim for at least 5 candidate sources per workstream.
- If fewer than 5 credible sources are found after all searches, emit:
  COVERAGE_WARNING: fewer than 5 candidate sources found - topic may be
  underrepresented in search results or search queries need refinement.
- This warning is informational; the orchestrator decides whether to re-search
  or continue with lower coverage.
```

#### Change 3.2 - Add controlled-vocabulary source quality labels

Current text:

```text
3) Candidate sources (max 15)
For each source:
- Title:
- URL:
- Why relevant (1 line):
- Credibility note (primary/secondary/vendor/blog/standard/paper/etc.):
```

Replace with:

```text
3) Candidate sources (max 15)
For each source:
- Title:
- URL:
- Why relevant (1 line):
- Tier: primary | secondary | tertiary
- Type: peer-reviewed | official-docs | government | standards-body |
         reputable-journalism | vendor | blog | preprint | other
- Additional note (optional): [any context beyond tier/type, e.g. "potentially outdated"]
```

#### Change 3.3 - Make counterpoint source type explicit

Current text:

```text
- Include at least one "counterpoint" or skeptical source if the topic is
  controversial or has competing perspectives.
```

Replace with:

```text
- Include at least one counterpoint or skeptical source if the topic is
  controversial or has competing perspectives. Mark it clearly as one of:
  opposing-interpretation | methodological-critique | deployment-caveat |
  benchmark-limitation | policy-disagreement
```

### File: `agents/research-fetcher.md`

#### Change 3.4 - Add optional verbatim support snippets

Current text:

```text
Key points (3-10 bullets)
- Bullets must be factual and specific.
```

Replace with:

```text
Key points (3-10 bullets)
- Bullets must be factual and specific.
- When a key point involves a number, a definition, a version claim, or a finding
  likely to be directly cited later, append a short [verbatim] support snippet inline.
  Example: "Patch available since v2.3.1 [verbatim: 'Fixed in release 2.3.1 (2024-03-14)']"
  Do not add [verbatim] snippets for routine contextual bullets - only for claims where
  exact wording or values materially affect interpretation.
```

#### Change 3.5 - Add `Source confidence` to security metadata

Current text:

```text
Security metadata (only if source discusses vulnerabilities/advisories)
- Identifier(s):
- Affected version(s):
- Patched/fixed version(s):
- Severity/score (if visible):
- Exploitation context (if visible):
```

Replace with:

```text
Security metadata (only if source discusses vulnerabilities/advisories)
For each field below, add a source confidence tag: (explicit) | (inferred) | (absent)
- Identifier(s):
- Affected version(s):
- Patched/fixed version(s):
- Severity/score:
- Exploitation context:
Use (explicit) when stated directly, (inferred) when derived from context,
(absent) when the source does not address the field. Do not write "Not stated."
```

### File: `agents/research-analyst.md`

#### Change 3.6 - Add finding strength tags

Current text:

```text
Findings
- 5-12 bullets, each written as a crisp claim.
- Each bullet must include evidence IDs in brackets, e.g. "... [1][3]"
```

Replace with:

```text
Findings
- 5-12 bullets, each written as a crisp claim.
- Each bullet must include evidence IDs in brackets, e.g. "... [1][3]"
- Each bullet must be tagged with exactly one strength label:
  - [strong]: backed by 2+ primary sources with no contradiction
  - [moderate]: backed by one primary source or multiple credible secondary sources
  - [weak]: backed only by weak, indirect, or limited evidence
  - [contested]: contradicted by another source in the Evidence Table
  Place the tag at the end of the bullet, e.g. "... [1][3] [strong]"
```

#### Change 3.7 - Add `Suggested action` to gap entries

Current text:

```text
Gaps & next fetches (FORMAL SIGNAL - orchestrator MUST act on these)
- 0-6 structured gap entries. For each gap, use this exact format:
  - Gap: [what is missing]
  - Priority: [critical / important / minor]
  - Source type needed: [e.g. peer-reviewed study, official API docs, regulatory filing]
  - Suggested query or URL pattern: [specific enough for orchestrator to act on]
```

Replace with:

```text
Gaps & next fetches (FORMAL SIGNAL - orchestrator MUST act on these)
- 0-6 structured gap entries. For each gap, use this exact format:
  - Gap: [what is missing]
  - Priority: [critical / important / minor]
  - Source type needed: [e.g. peer-reviewed study, official API docs, regulatory filing]
  - Suggested query or URL pattern: [specific enough for orchestrator to act on]
  - Suggested action: search | fetch | user-input
```

#### Change 3.8 - Increase analyst step budget

Current text:

```text
steps: 12
```

Replace with:

```text
steps: 16
```

### File: `agents/research-critic.md`

#### Change 3.9 - Add `Resolution recommendation` to risk-ranked findings

Current text:

```text
Risk-ranked findings
- 1-8 bullets, each tagged with exactly one priority label:
  - [critical] [important] [minor]
- Security findings (CVE/advisory/exploitability/patch claims) MUST be tagged
  [critical] unless explicitly low-impact with evidence.
- Each bullet should include: finding, impact, and what must be verified next.
```

Replace with:

```text
Risk-ranked findings
- 1-8 bullets, each tagged with exactly one priority label:
  - [critical] [important] [minor]
- Security findings (CVE/advisory/exploitability/patch claims) MUST be tagged
  [critical] unless explicitly low-impact with evidence.
- Each bullet must include: finding, impact, what must be verified next, and a
  resolution recommendation - exactly one of:
  fetch | rewrite | limitations | escalate
```

#### Change 3.10 - Add 3-search cap on proactive counterevidence search

Current text:

```text
### Proactive counterevidence search
- You are encouraged to use `exa_web_search_exa` proactively to find
  counterevidence, rebuttals, or alternative perspectives - not just to
  verify proposed URLs. Cite the search query used alongside each proposed source.
- Do not fetch or extract content from any URL. Searching only.
```

Replace with:

```text
### Proactive counterevidence search
- You may use `exa_web_search_exa` proactively to find counterevidence, rebuttals,
  or alternative perspectives - not just to verify proposed URLs.
- Limit proactive searches to at most 3 per invocation. Prioritize the
  highest-risk findings first.
- Cite the search query used alongside each proposed source.
- Do not fetch or extract content from any URL. Searching only.
```

#### Change 3.11 - Increase critic step budget

Current text:

```text
steps: 10
```

Replace with:

```text
steps: 12
```

### Phase 3 Done-Checklist

- [ ] `research-searcher.md`: `COVERAGE_WARNING` rule added for fewer than 5 sources
- [ ] `research-searcher.md`: candidate sources use `Tier` + `Type`
- [ ] `research-searcher.md`: counterpoint source type classification added
- [ ] `research-fetcher.md`: `[verbatim]` snippet guidance added
- [ ] `research-fetcher.md`: security metadata uses confidence tags
- [ ] `research-analyst.md`: finding strength tags added
- [ ] `research-analyst.md`: `Suggested action` field added to gaps
- [ ] `research-analyst.md`: `steps` increased from 12 to 16
- [ ] `research-critic.md`: `Resolution recommendation` field added
- [ ] `research-critic.md`: proactive search capped at 3 per invocation
- [ ] `research-critic.md`: `steps` increased from 10 to 12

## Phase 4 - Writer Improvements + Model Review

Goal: Make the writer confidence-sensitive, fix the citation-gap blocking
behavior, add scope guidance, and review model assignments across all agents.

Rationale: The writer improvements depend on analyst strength tags from Phase 3.
The model review is last because the right model choice for each role depends on
what that role is being asked to do after all prompt changes are in place.

### File: `agents/research-writer.md`

#### Change 4.1 - Make prose tone confidence-sensitive

Add after the quotes rule:

```text
### Confidence-calibrated prose (MANDATORY)
Calibrate language tone to the analyst strength tag of each finding:
- [strong]: use direct declarative language. ("X is the case.")
- [moderate]: use lightly qualified language. ("Evidence suggests X." / "X appears to...")
- [weak]: use clearly tentative language. ("Limited evidence indicates..." / "It may be that...")
- [contested]: state both positions and note the disagreement explicitly.
  ("Source A reports X [1], while Source B argues Y [2]. This remains unresolved.")
Do not use definitive language for [weak] or [contested] findings regardless of
how the orchestrator framed them in the handoff.
```

#### Change 4.2 - Change `CITATION_GAP` to partial-draft behavior

Current text:

```text
### Citation gap handling (MANDATORY)
- Before drafting, audit the provided outline against the Evidence Table.
- If any section of the outline contains a claim with no corresponding
  evidence ID in the Evidence Table, do NOT draft that section. Instead,
  return ONLY:
  CITATION_GAP: [section name] - [description of missing evidence]
- The orchestrator must resolve all citation gaps before you resume drafting.
- Only proceed to full draft when every planned citation maps to an evidence ID.
```

Replace with:

```text
### Citation gap handling (MANDATORY)
- Before drafting, audit the provided outline against the Evidence Table.
- Draft all sections that are fully supported (every planned citation maps to
  an evidence ID in the Evidence Table).
- For each section that cannot be drafted due to missing evidence, emit:
  CITATION_GAP: [section name] - [description of missing evidence]
  Do not draft that section. Continue drafting all other supported sections.
- After completing the partial draft, list all blocked sections at the end:
  BLOCKED SECTIONS: [list]
- The orchestrator must resolve all citation gaps and re-invoke the writer
  for blocked sections only.
```

#### Change 4.3 - Add length guidance

Add to the style rules section:

```text
### Length guidance
- Normal high-rigor research (3-5 workstreams): concise but complete. Each section
  should cover its evidence without expanding into tangents.
- Broader research (6+ workstreams): may be longer, but each section remains tightly
  scoped. Do not re-summarize earlier sections in later ones.
- Avoid expanding individual sections unless the orchestrator or user explicitly
  requests more depth.
```

### Model Review (all agents)

This is a discussion and documentation item rather than a mechanical edit.
After all prompt and contract changes are in place, evaluate each model
assignment against the role's new contract:

| Agent | Current model | Role demand after changes | Recommendation |
|---|---|---|---|
| `research-searcher` | `opencode/minimax-m2.5` | Source quality judgment, controlled-vocab labels, coverage assessment | Worth evaluating a stronger reasoning model |
| `research-fetcher` | `opencode/kimi-k2.5` | Structured extraction, verbatim snippet identification, security metadata confidence tagging | High-value role; extraction reliability matters most |
| `research-analyst` | `opencode/glm-5` | Multi-source synthesis, strength tagging, gap signaling with action types | Central reasoning role; most sensitive to model quality |
| `research-critic` | `opencode/glm-5` | Adversarial review, bounded counterevidence search, resolution recommendations | Consider whether same or different model is better than analyst |
| `research-writer` | `opencode/minimax-m2.5` | Confidence-calibrated prose, partial-draft logic, citation fidelity | Evaluate separately from searcher |
| `research-verifier` | `<unset>` | Pure audit reasoning, no tools, conservative classification | Reasoning quality and instruction-following precision are key |

Model changes should happen at the end of Phase 4 after all other changes are
applied and validated.

### Phase 4 Done-Checklist

- [ ] `research-writer.md`: confidence-calibrated prose rules added
- [ ] `research-writer.md`: citation gap handling changed to partial-draft behavior
- [ ] `research-writer.md`: length guidance added
- [ ] model review conducted; `research-verifier.md` model field set
- [ ] any other model field updates applied and documented

## Summary Table

| Phase | Files changed | Change count | Risk | Key dependency |
|---|---|---|---|---|
| **0 - Cleanup** | `research.md`, `research-searcher.md`, `research-fetcher.md`, `research-analyst.md`, `research-critic.md` | 7 | Low | None |
| **1 - Orchestrator** | `research.md` | 7 | Medium | Phase 0 |
| **2 - Verifier** | `research-verifier.md` (new), `research.md` | 4 | Medium | Phase 1 |
| **3 - Subagent contracts** | `research-searcher.md`, `research-fetcher.md`, `research-analyst.md`, `research-critic.md` | 11 | Low-Medium | Phase 2 |
| **4 - Writer + Models** | `research-writer.md`, all agents (model fields) | 4 + model review | Low | Phase 3 |
| **Total** | 7 files | ~33 discrete edits | - | - |
