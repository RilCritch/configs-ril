# Research Agent High-Rigor Improvement Plan

## Overview and Guiding Principles

This plan is built on three premises established by the initial investigation and the follow-up research:

1. The current architecture is fundamentally correct. The orchestrator + specialist subagent pattern is well-supported and should be preserved.
2. The goal of this agent is high-rigor research, not fast lightweight search. Optimization should improve correctness, reliability, and traceability rather than collapsing the workflow into a simpler search-only flow.
3. The strongest opportunities are to reduce unnecessary orchestration overhead, add explicit citation-validation, strengthen subagent contracts, replace redundant late-stage re-analysis with a conditional final check, and improve handoff quality between agents.

The current system is already aligned with many best practices:

- explicit plan approval before browsing,
- evidence-first workflow,
- specialized subagents,
- dedicated critique,
- provenance and citation requirements,
- security-specific verification rules.

The plan below is therefore evolutionary rather than a rewrite. It is designed to preserve the current system's strengths while removing structural weakness and brittleness.

---

## Main Research Agent: `agents/research.md`

### 1. Frontmatter and Permission Alignment

#### Current issue

The frontmatter allows `grep`, but the prompt-level approval gate says the only pre-approval tools are `question`, `todowrite`, `todoread`, `read`, `glob`, and `list`. This is a direct mismatch between the machine-readable and natural-language policies.

#### Improvement

Align the two sources of truth.

- Either add `grep` to the allowed pre-approval tool list in the prompt rules, or remove it from the permission block.
- The better option is to keep `grep` allowed and explicitly include it in the pre-approval list, because local repo exploration can sometimes require content search before finalizing the plan.

#### Additional frontmatter update

Add the new `research-verifier` subagent to the `task` allow-list once it is introduced.

---

### 2. Preserve the Hard Approval Gate, but Clarify Interruption Policy

#### What should remain unchanged

The strict plan confirmation gate is one of the strongest parts of the system and should remain in place exactly in spirit. A high-rigor research agent benefits from not browsing or spawning subagents until a plan is approved.

#### Current issue

The orchestrator currently pauses the user in too many different ways and for too many different reasons. Some pauses are necessary and some are just side effects of process-heavy design.

#### Improvement

Add a dedicated interruption policy section that classifies pause conditions into three categories.

##### Mandatory interruption

The agent must pause and ask the user only when:

- a critical security contradiction remains unresolved after the allowed critique cycles,
- a subagent fails its contract twice in a row,
- the user must make a value judgment that cannot be inferred from evidence,
- the research can no longer continue without a user decision.

##### Conditional interruption

The agent may pause only if the issue blocks report integrity:

- unresolved non-security contradiction that prevents drafting,
- a critical gap that cannot be filled with search/fetch,
- a source conflict that changes the conclusion materially.

##### Non-blocking carry-forward

These should not trigger a user pause and should instead flow into final limitations:

- minor evidence gaps,
- partially-supported claims that can be downgraded,
- inconclusive but low-risk disagreements,
- unresolved secondary detail that does not change the core conclusion.

This reduces unnecessary interruptions while keeping the fail-closed behaviour where it matters.

---

### 3. Tighten Intake Behaviour in Phase 0

#### Current issue

The orchestrator is allowed to ask 3-7 intake questions. In practice, that is too many for most sessions and encourages over-questioning.

#### Improvement

Reduce the effective maximum to 3 targeted questions. Each question should cover one unknown dimension only:

- objective or decision being supported,
- scope/timeframe/depth,
- output shape.

If one of those is already clear from the user's prompt, skip it entirely. This keeps intake focused without weakening the rigor of later phases.

---

### 4. Improve Phase 1 Planning Discipline

#### Current issue

The orchestrator asks for workstreams but does not define what a workstream is or how granular they should be. This creates uneven planning quality.

#### Improvement

Add an explicit workstream definition:

- a workstream is a distinct angle of inquiry that requires its own discovery pass,
- each workstream should be broad enough to justify multiple candidate sources,
- each workstream should be narrow enough to produce actionable search queries,
- if a workstream would only generate a subsection rather than a distinct research track, merge it,
- if a workstream lacks any clear primary source path, mark it as exploratory in the plan.

This will improve downstream delegation quality and prevent shallow or redundant workstreams.

---

### 5. Simplify Phase 2 State Initialization

#### Current issue

The orchestrator currently initializes too much state too early and must then maintain it manually across a long session.

#### Improvement

Keep the existing three artifacts, but simplify how they start:

- `todowrite`: initialize high-level phase tasks first, then expand when workstreams are approved.
- `Research State`: keep it short, and require one line indicating what changed since the previous state.
- `Evidence Table`: create only the header scaffold in Phase 2; do not create placeholder rows.

This keeps the state machinery useful without turning it into ceremony.

---

### 6. Strengthen Discovery in Phase 3

#### Current issue

The orchestrator currently allows searcher delegation "per workstream (or batch if small)." That batching clause conflicts with the searcher's single-workstream output contract and creates avoidable ambiguity.

#### Improvement

Remove batching for `research-searcher` entirely.

- Always invoke one searcher per workstream.
- When workstreams are independent, delegate them in parallel.
- Consolidate all shortlists centrally in the orchestrator before fetching.

This preserves the clean subagent role boundary while improving throughput via parallel execution rather than mixed prompts.

---

### 7. Make Evidence Alignment a Hard Checklist

#### Current issue

The Evidence Alignment Check is present, but it is easy for the orchestrator to skate past it because it is written as prose rather than a concrete checklist.

#### Improvement

Rewrite it as an explicit pre-critique gate. Before Phase 6 starts, the orchestrator must confirm:

1. every evidence ID used by analysts exists in the Evidence Table,
2. every analyst-flagged critical gap is either resolved or explicitly carried forward,
3. every `UNVERIFIED_HIGH_RISK` item has source-tier notes in the Evidence Table,
4. no unsupported evidence references remain from synthesis.

If any check fails, fix it before critique begins.

---

### 8. Add a Dedicated Citation Verification Phase

#### Why this is needed

The research established a major gap in the current setup: strong provenance tracking is not the same thing as claim-to-source validation. Current AI systems often cite poorly even when they look well-structured.

The current pipeline can collect sources and assign evidence IDs, but it does not have a dedicated agent that answers the most important citation question:

"Does this specific claim actually follow from the sources it cites?"

#### Improvement

Add a new subagent, `research-verifier`, and a new phase between synthesis and critique.

##### New phase placement

Add a new step after Phase 5:

`Phase 5b - Citation Verification`

##### Responsibilities of the orchestrator in this phase

- send analyst findings and the full Evidence Table to `research-verifier`,
- receive verdicts on each finding: supported / partially-supported / unsupported / misattributed,
- resolve every unsupported or misattributed finding before critique begins,
- downgrade partially-supported findings before handing them to the critic.

This one addition closes the largest structural gap identified in the research.

---

### 9. Refine the Critique Loop in Phase 6

#### Current issue

The current critique loop is directionally correct but underspecified about scope. "Any contradiction MUST trigger a re-fetch cycle" is too broad and could cause unnecessary expansion.

#### Improvement

Clarify that contradiction-driven re-fetching must be targeted.

- Re-fetch only the claims or evidence rows directly implicated by the critic.
- Do not re-run broad discovery unless the contradiction clearly indicates the current evidence pool is structurally insufficient.
- Prefer critic-proposed primary sources first.
- Limit each critique cycle to resolving the highest-risk items first.

Also consolidate all critical-security fail-closed logic in this phase instead of splitting it across Phase 6 and Quality Gate B.

---

### 10. Replace Phase 7 With a Conditional Final Check

#### Current issue

The current Phase 7 repeats synthesis and critique even when Phase 6 already resolved everything. That adds cost and prompt complexity without adding proportionate rigor.

#### Improvement

Replace Phase 7 with a conditional final check.

##### New behaviour

- If Phase 6 resolves cleanly: skip Phase 7 entirely and move to drafting.
- If Phase 6 ends with unresolved but user-approved caveats or remaining carried-forward contradictions: run one narrow final check only on affected workstreams.

##### Scope of the conditional check

- one final analyst pass for only the affected claims/workstreams,
- one final critic pass for only those unresolved items,
- no broad re-run of the whole pipeline.

This preserves thoroughness without duplicating the entire late-stage process.

---

### 11. Formalize the Writer Handoff in Phase 8

#### Current issue

The writer currently receives "final outline, evidence table, citation rules," which is too vague. The writer depends heavily on orchestrator packaging quality.

#### Improvement

Define a mandatory Writer Handoff Package with these sections:

1. final outline with section-to-evidence mapping,
2. current Evidence Table,
3. resolved contradictions summary,
4. unresolved items and required limitations language,
5. confidence level of key findings where relevant,
6. citation density expectation for the report.

This reduces writer drift and produces more faithful final reports.

---

### 12. Tighten Formatting and State Reporting

#### Improvement

- Change `Research State` to a visible markdown heading such as `### Research State`.
- Add a max-length expectation: 5 lines or fewer.
- Use it only for phase transitions and meaningful state changes.
- Put detailed operational tracking in the todo list, not in the conversation narrative.

This keeps the live process readable in long research sessions.

---

## Searcher Subagent: `agents/research-searcher.md`

### 1. Separate Search Strategy From Searches Performed

#### Current issue

The current `Query set` mixes queries that were actually used with those the model merely "would use." This weakens auditability.

#### Improvement

Split the current section into two:

- `Search strategy`: 3-6 query directions or query families, with a short reason.
- `Searches performed`: exact `exa_web_search_exa` queries actually executed.

This gives both planning transparency and real tool-call traceability.

---

### 2. Add a Minimum Coverage Requirement

#### Current issue

The candidate source list has a maximum but no minimum. A high-rigor search phase should not quietly return a tiny pool of evidence unless that scarcity is made explicit.

#### Improvement

Require at least 5 candidate sources when possible.

If fewer than 5 credible candidate sources are found, the searcher must emit:

`COVERAGE_WARNING: fewer than 5 candidate sources found - topic may be underrepresented in search results.`

This allows the orchestrator to treat low-coverage workstreams as higher-risk.

---

### 3. Standardize Source Quality Labels

#### Current issue

The current credibility note is too freeform and tends to become inconsistent across invocations.

#### Improvement

Replace the current loose note style with a controlled vocabulary.

Each candidate source should carry:

- `Tier`: `primary` | `secondary` | `tertiary`
- `Type`: `peer-reviewed` | `official-docs` | `government` | `standards-body` | `reputable-journalism` | `vendor` | `blog` | `preprint` | `other`

Optional additional note text may be included after those fields if needed.

This makes downstream evidence grading much more consistent.

---

### 4. Preserve Counterpoint Searching, but Make It Explicitly Structured

#### Improvement

Keep the existing requirement to include at least one skeptical or counterpoint source when the topic is controversial. Add wording that this source must be clearly marked as one of:

- opposing interpretation,
- methodological critique,
- deployment caveat,
- benchmark limitation,
- policy disagreement.

This helps the orchestrator understand why the counterpoint exists and how to use it.

---

### 5. Model Recommendation

The searcher currently uses `opencode/minimax-m2.5`. This role requires reliable instruction-following, query formulation, source triage, and quality judgments. It is worth evaluating whether a stronger reasoning-oriented model would produce more consistent source grading and fewer format issues. This is not a mandatory change, but search quality materially affects the entire pipeline, so the role is worth revisiting.

---

## Fetcher Subagent: `agents/research-fetcher.md`

### 1. Improve Claim Traceability in Extracted Notes

#### Current issue

The fetcher returns good source summaries, but downstream claim-to-source validation still relies on implicit interpretation. There is no explicit traceability aid for later verification.

#### Improvement

Extend the `Key points` section so that when a key point is directly supported by a short extract from the page, the fetcher can attach a short `[verbatim]` support snippet inline.

This is not for every bullet. It should be used when:

- a number matters,
- wording materially affects interpretation,
- a claim is likely to be cited later,
- the verifier will need direct support.

This will materially improve the quality of the new `research-verifier` phase.

---

### 2. Relax the ACCESS_ERROR Threshold

#### Current issue

The rule that pages with fewer than 3 extractable facts count as `ACCESS_ERROR` is too brittle. Some very short official or authoritative sources contain only 1-2 critical facts and are still valuable.

#### Improvement

Redefine `ACCESS_ERROR` to mean:

- paywall,
- login wall,
- empty or boilerplate page,
- extraction failure so severe that no domain-relevant facts can be recovered.

Short but useful sources should be extracted normally and tagged with a caveat such as `brief source; limited detail` rather than marked inaccessible.

---

### 3. Strengthen Security Metadata Extraction

#### Current issue

Security metadata currently collapses all missing information into `Not stated.` That loses a distinction between "explicitly absent" and "not extractable from this source."

#### Improvement

Add a `Source confidence` field for each security metadata item:

- `explicit`
- `inferred`
- `absent`

This will help the orchestrator treat security claims more carefully and preserve the quality of the security verification protocol.

---

### 4. Model Recommendation

The fetcher currently uses `opencode/kimi-k2.5`. This role is accuracy-critical because every downstream stage depends on the quality of extraction. If there is any evidence of dropped details, over-summary, or fabricated metadata, this would be one of the highest-value roles to upgrade. The fetcher is a strong candidate for a model chosen primarily for reading comprehension and structured extraction reliability.

---

## Analyst Subagent: `agents/research-analyst.md`

### 1. Add Finding Strength Classifications

#### Current issue

All findings currently look equivalent except for their citation count. That makes it harder for the critic, writer, and orchestrator to calibrate confidence.

#### Improvement

Add an explicit strength tag to each finding:

- `[strong]`: backed by 2+ primary sources with no contradiction,
- `[moderate]`: backed by one primary source or multiple secondary sources,
- `[weak]`: backed only by weak or limited evidence,
- `[contested]`: contradicted by another source.

This will improve downstream writing tone, contradiction handling, and prioritization.

---

### 2. Clarify the Uncertainty Type Hierarchy

#### Current issue

The current uncertainty prefixes are useful, but their boundaries overlap.

#### Improvement

Define a precedence order:

1. `UNVERIFIED_HIGH_RISK` takes precedence when the issue is security-sensitive or otherwise materially risky.
2. `CONFLICTING_EVIDENCE` applies when sources disagree materially and no high-risk rule overrides.
3. `INSUFFICIENT_PRIMARY_SOURCE` applies when evidence is not contradicted but remains too weakly sourced.

This reduces ambiguity and improves orchestrator behaviour.

---

### 3. Make Gap Signals More Actionable

#### Current issue

The current `Gaps & next fetches` format is strong but still leaves too much interpretation burden on the orchestrator.

#### Improvement

Add a `Suggested action` field for each gap:

- `search`
- `fetch`
- `user-input`

This makes the gap signal operationally precise rather than advisory.

---

### 4. Increase Analyst Step Budget

#### Current issue

The analyst currently has `steps: 12`. For dense workstreams this can be tight and risks weaker synthesis or poorer gap recommendations.

#### Improvement

Increase to `steps: 16`.

This role is central to research quality and should have enough headroom to think clearly over large evidence sets.

---

## Critic Subagent: `agents/research-critic.md`

### 1. Add Explicit Resolution Recommendations

#### Current issue

The critic flags problems well, but the orchestrator must still infer the proper next action from each one.

#### Improvement

Add a `Resolution recommendation` element to each risk-ranked finding. The critic should recommend one of:

- `fetch`
- `rewrite`
- `limitations`
- `escalate`

This gives the orchestrator a direct operational response path.

---

### 2. Replace Forced Weakness With Explicit Certification

#### Current issue

The critic is forced to output at least one weak-claims bullet, even if no real weakness exists. This can produce performative skepticism.

#### Improvement

Replace the minimum-one-bullet requirement with an explicit certification option such as:

`CLAIMS CERTIFIED: all major findings have primary source support with no material weaknesses identified.`

This still forces a judgment while reducing artificial criticism.

---

### 3. Put a Bound on Proactive Counterevidence Search

#### Current issue

The critic is encouraged to proactively search for counterevidence, but this can spiral.

#### Improvement

Add a scope rule: at most 3 proactive searches per invocation, and only for the highest-risk findings first.

This keeps the critic sharp rather than diffuse.

---

### 4. Increase Critic Step Budget Slightly

#### Improvement

Increase `steps` from 10 to 12. The critic must verify proposed sources, perform bounded proactive search, and still produce structured output. A small increase improves reliability without encouraging bloat.

---

## Writer Subagent: `agents/research-writer.md`

### 1. Make Writing Confidence-Sensitive

#### Current issue

The writer currently receives too little structured confidence context. That encourages a uniform tone even when evidence quality differs.

#### Improvement

Update writer rules so prose is calibrated to finding strength tags from the analyst:

- `[strong]`: direct declarative language,
- `[moderate]`: lightly qualified language,
- `[weak]`: clearly tentative language,
- `[contested]`: state both positions and note the disagreement.

This will make final reports more epistemically honest.

---

### 2. Improve Citation Gap Handling

#### Current issue

The current `CITATION_GAP` rule blocks the entire report when one section lacks support.

#### Improvement

Change this to partial-draft behaviour.

- Draft all sections that are fully supported.
- Emit `CITATION_GAP` notices only for blocked sections.
- Tell the orchestrator which sections are completed and which are blocked.

This is more operationally efficient and still maintains rigor.

---

### 3. Add Length Guidance

#### Current issue

The writer has readability guidance but no overall scope guidance. That can produce overly long outputs.

#### Improvement

Add length guidance relative to project size:

- normal high-rigor research: concise but complete,
- broader 6+ workstream research: may be longer, but each section should remain tightly scoped,
- avoid over-expanding individual sections unless explicitly asked.

---

### 4. Model Recommendation

The writer currently uses `opencode/minimax-m2.5`. This role depends on clear exposition, structural discipline, and strong citation obedience. It is worth reviewing separately from the searcher because the writing role and the discovery role have different strengths.

---

## New Required Agent: `agents/research-verifier.md`

### 1. Why a New Agent Is Required

This is the most important structural addition.

The current system already has:

- a searcher to find sources,
- a fetcher to extract them,
- an analyst to synthesize,
- a critic to challenge,
- a writer to draft.

What it does not have is a dedicated citation-validation agent that checks whether each cited finding is actually supported by the cited evidence.

The research showed that this is a real gap in modern AI research systems. Provenance tracking alone is not enough. A system can have citations and still cite badly.

Because this responsibility is distinct from synthesis and distinct from critique, it should be a separate subagent rather than an extension of the analyst.

---

### 2. Proposed Role

The verifier's job is narrow and strict:

- read analyst findings,
- inspect the cited evidence rows,
- determine whether each finding is actually supported by its evidence IDs,
- flag unsupported, partially-supported, or misattributed claims,
- never search, browse, or introduce new evidence.

This preserves the current role separation and keeps the analyst pure.

---

### 3. Proposed Placement in the Pipeline

Insert the verifier between synthesis and critique.

New sequence:

1. search
2. fetch
3. analyze
4. verify
5. critique
6. conditional final check
7. draft

This is the best point in the pipeline because the analyst has already created claims, but the critic has not yet begun pressure-testing. The verifier therefore improves the quality of what the critic receives.

---

### 4. Proposed Frontmatter

```yaml
---
description: Validates that each cited finding is traceable to its stated evidence. Flags unsupported claims and misattributions before critique.
mode: subagent
model: <to be selected>
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
```

The verifier should have no tool access. It must work entirely from the provided Evidence Table and findings.

---

### 5. Proposed Output Contract

```text
Claim verification results

For each analyst finding bullet:
- Claim: [exact finding text]
- Evidence IDs cited: [e.g. [1][3]]
- Verification status: supported | partially-supported | unsupported | misattributed
- Rationale: [1-2 lines]
- Unsupported portion (if any): [what aspect was not supported]

Summary
- Total claims reviewed:
- Supported:
- Partially-supported:
- Unsupported:
- Misattributed:

Escalations
- For each unsupported or misattributed claim:
  - Claim:
  - Recommended action: re-fetch source | downgrade to [weak] | remove claim | user-input needed
```

---

### 6. Verification Status Definitions

To keep the verifier consistent, define the statuses explicitly.

- `supported`: the cited evidence directly supports the claim.
- `partially-supported`: the main claim is supported, but some element overreaches.
- `unsupported`: the cited evidence does not substantiate the claim.
- `misattributed`: the evidence is about something materially different than the claim.

---

### 7. Proposed Rules

The verifier rules should include:

- do not browse,
- do not search,
- do not propose new evidence,
- do not rewrite claims,
- be conservative when uncertain,
- classify borderline cases as `partially-supported` rather than `supported`,
- return full structured output even if every claim passes.

This makes the verifier an audit layer, not another synthesizer.

---

### 8. Proposed Integration Into `research.md`

The orchestrator will need:

- updated frontmatter permissions for `research-verifier`,
- a new `Phase 5b - Citation Verification`,
- logic stating that unsupported or misattributed claims must be resolved before critique begins.

This creates a cleaner, more rigorous transition from synthesis to critique.

---

## Cross-Cutting Operational Recommendations

### 1. Preserve High-Rigor Identity

This system should remain the high-rigor research agent. It should not be simplified into a quick-search agent. The right way to handle faster research is with a different agent, not by weakening this one.

### 2. Prefer Parallelism Over Batching

When workstreams are independent, parallel delegation is the right optimization. It improves runtime without sacrificing the clarity of single-purpose prompts.

### 3. Shift From Procedural Complexity to Structural Clarity

The main theme of improvement is not "do less research." It is "use clearer phase boundaries, stronger contracts, and more deterministic handoffs." The system should feel more disciplined, not lighter-weight.

### 4. Preserve Fail-Closed Behaviour for Security and Major Contradictions

High-rigor research should still fail closed where stakes are high. That principle is correct in the current design and should remain intact.

---

## Implementation Order Recommendation

The best implementation order is:

1. Add `research-verifier.md`
2. Update `research.md` to include the new phase and conditional Phase 7
3. Tighten searcher contract
4. Improve fetcher output for traceability
5. Upgrade analyst finding structure
6. Improve critic resolution output
7. Improve writer handoff and citation-gap behaviour
8. Re-evaluate model assignments after prompt/contract updates are complete

This order minimizes disruption and ensures the biggest structural improvement lands first.

---

## Final Direction

The current system is already on the right path for a high-rigor research agent. It has the right instincts and the right skeleton. The improvements above do not change its identity. They sharpen it.

After these changes, the system should be:

- more rigorous in claim-to-source validation,
- less procedurally noisy,
- easier for the orchestrator to manage,
- more consistent across workstreams,
- more faithful in final reporting,
- and better aligned with what the research suggests actually works in high-rigor AI deep research systems.
