# OpenCode Deep Research Agent Update Notes
Various notes related to my OpenCode Deep Research agent setup

# Sub-Agent Models

## Research - Orchestration Agent
- Kimi K2.5
## Research-Searcher
- Claude Haiku 4.5
## Research-Fetcher
- Gemini 3.1 Pro
## Research-Analyst
- Gemini 3.1 Pro
## Research-Verifier
- Claude Haiku 4.5
## Research-Critic
- Claude Sonnet 4.6
## Research-Writer
- Gemini 3.1 Pro

# Kimi K2.5 Optimizations
## Settings, Parameters, Instructions Tips
Kimi K2.5 Foundational Configuration: Core Concepts for Research-Agent Improvement
Goal of this section
Configure Kimi K2.5 as an orchestrator, not as a general chatbot or writer. Its primary job is to:
- make workflow decisions
- enforce research phase gates
- route tasks to sub-agents accurately
- maintain coherence across long, tool-heavy workflows
Core concept 1: Optimize for orchestration, not prose
Kimi should be tuned for:
- delegation
- evaluation of sub-agent outputs
- structured tool use
- state-aware workflow control
It should not be optimized primarily for creative writing or freeform synthesis.
Core concept 2: Use Thinking mode for orchestration
The section recommends using Kimi’s Thinking mode because the orchestrator needs extra reasoning before:
- approving phase transitions
- validating sub-agent responses
- invoking tools
- resolving conflicting evidence
The idea is that “thinking” improves deliberation before action.
Core concept 3: Recommended inference settings
The section proposes a baseline orchestrator configuration roughly like this:
- temperature: 1.0
- top_p: 0.95
- large max_tokens budget
- thinking/reasoning enabled
- tool_choice: auto
The intended effect is:
- better expert routing
- fewer repetitive or collapsed decisions
- more reliable tool invocation
- less truncation in long research sessions
Core concept 4: Exploit Kimi’s native parallel-agent strengths
Kimi K2.5 is presented as naturally strong at:
- decomposing work into subtasks
- delegating independent tasks in parallel
- maintaining coherence across many tool calls
For a research system, this means the orchestrator should:
- split research into distinct workstreams
- launch one discovery/search task per workstream
- run those in parallel where possible
- merge results centrally
Core concept 5: Map workstreams explicitly to parallel subtasks
The section emphasizes that the prompt and orchestration layer should clearly define:
- what counts as a workstream
- which workstreams are independent
- when parallel execution is allowed
- when the orchestrator must pause for validation before continuing
This helps the model use parallelism intentionally rather than chaotically.
Core concept 6: Reserve deeper reasoning for harder phases
Not every phase needs maximum deliberation. The section implies a pattern where:
- lighter reasoning is used for routine routing and intake
- heavier reasoning is used for critique, contradiction resolution, and quality-gate decisions
This suggests a planning principle:
- use Kimi’s reasoning budget selectively
- spend more tokens where correctness matters most
Core concept 7: Prevent failures in long-horizon orchestration
The whole configuration strategy is meant to reduce:
- bad tool calls
- hallucinated routing decisions
- context drift
- workflow collapse during long research runs
- loss of structure late in the process

## OpenCode Optimizations for Kimi K2.5 Orchestrator
This section proposes configuring OpenCode as a strict execution boundary around Kimi K2.5 so the model behaves like a read-only research orchestrator rather than a general autonomous agent.
Main objective
Use OpenCode’s configuration system to enforce:
- role separation
- tool restrictions
- subagent isolation
- zero-trust operational boundaries
The key idea is that prompt instructions are not enough.  
If the orchestrator must not edit files, run shell commands, or directly browse/fetch, those capabilities should be blocked at the permission layer.
Core concepts
1. OpenCode is the runtime control layer
OpenCode is the system that connects the model to tools such as:
- filesystem access
- bash/shell
- web access
- subagent delegation
- skill loading
Because of this, OpenCode defines the model’s real operating boundaries.
2. Use primary agent vs subagent mode for separation
The orchestrator should be configured as the primary agent.  
Specialists such as searcher, fetcher, analyst, verifier, critic, and writer should be configured as subagents.
The purpose is context isolation:
- the orchestrator owns the main workflow
- each specialist runs in an isolated context
- raw retrieval output, analyst synthesis, and critic debate should not all mix in one context window
This makes the orchestrator an information membrane that passes only the required structured payloads between agents.
3. Apply zero-trust permission hardening
The section recommends inverting OpenCode’s permissive defaults and moving to a zero-trust model.
This means:
- deny tools the orchestrator should never use
- only allow the minimum tools required for orchestration
- rely on transport-layer enforcement, not just prompt compliance
4. Deny role-breaking tools for the orchestrator
The orchestrator should generally be blocked from:
- file editing / writing / patching
- bash/shell execution
- direct web fetching
The orchestrator should mainly retain:
- task for delegating to subagents
- skill for loading specialized instructions
This preserves the orchestrator’s role as coordinator rather than executor.
5. Permission failures are a feature
If the orchestrator attempts an unauthorized action, OpenCode should reject it immediately.
This is important because it:
- prevents silent role drift
- prevents hallucinated assumptions that an action succeeded
- forces the orchestrator to revise its plan within allowed boundaries
6. Use loop protection for unresolved cycles
The section also recommends keeping safeguards like doom_loop active or approval-gated so repeated failed attempts or contradiction loops can be interrupted and escalated instead of running indefinitely.
---
What this section is trying to achieve
This section is trying to create an architecture where:
- Kimi K2.5 is a constrained coordinator
- specialists do the execution work
- context contamination is minimized
- dangerous capabilities are removed from the orchestrator
- system safety comes from runtime enforcement, not trust in model obedience

## Prompt Optimization Through Commands, Skills, etc.
This section proposes a progressive disclosure architecture for a Kimi K2.5 research orchestrator. The main idea is that the orchestrator should not keep the full multi-phase research protocol loaded in its prompt at all times. Instead, it should load only the instructions needed for the current phase or special situation.
Main objective
Reduce prompt bloat and improve orchestration reliability by using:
- commands for phase-level workflow control
- skills for specialized procedures that are only needed in certain contexts
This keeps the base orchestrator prompt lean while still allowing deep procedural guidance when required.
---
Core concepts
1. Progressive disclosure
Rather than front-loading all workflow instructions into the main system prompt, the orchestrator should receive instructions just in time.
The intended benefits are:
- lower prompt complexity
- less attention dilution
- better focus on the active phase
- more room in context for evidence and state
2. Commands as workflow gates
Custom commands should define clear entry points for major workflow phases.
Examples described in the section:
- an intake command for Phase 0
- a planning/proposal command for Phase 1
- a handoff-generation command for the late drafting stage
Commands serve as macro-instructions that:
- constrain the agent to one stage of work
- enforce structured outputs
- preserve approval gates and pauses between major transitions
3. Skills as dynamic specialist instructions
Skills are modular instruction bundles that the orchestrator loads only when needed.
The orchestrator’s base prompt should only reference available skills.  
When a specific situation occurs, the orchestrator loads the relevant skill dynamically.
This allows specialized protocols to remain available without permanently occupying prompt space.
4. Example use cases for skills
The section highlights two types of skills:
- contradiction resolution skill for handling disputes between analyst and critic outputs
- security/CVE protocol skill for high-risk vulnerability research requiring stricter evidence rules
These skills encode rigid procedural logic for special cases, rather than leaving the model to improvise.
5. Commands control when, skills control how
A useful planning distinction from this section is:
- commands determine when a workflow phase starts and what output shape it should produce
- skills determine how specialized reasoning or enforcement should happen inside a phase
This creates a layered control model:
- phase orchestration through commands
- conditional protocol injection through skills
6. Lean core prompt, richer situational behavior
The section’s overall design pattern is:
- keep the orchestrator’s permanent prompt small and stable
- dynamically inject context-specific instructions as the workflow evolves
This is intended to make the orchestrator more reliable across long research sessions and reduce confusion from carrying unnecessary instructions.
---
What this section is trying to achieve
This section is trying to build a research orchestrator that:
- stays focused on the current phase
- avoids prompt overload
- uses explicit workflow entry points
- applies specialized procedures only when relevant
- preserves context space for evidence, memory, and active reasoning
 
## System Prompt Tips for the Kimi K2.5 Research Orchestrator
This section proposes that the master orchestrator needs a strong, always-on system prompt that defines its permanent role, boundaries, and control logic. Even if commands, skills, and external memory are used, the orchestrator still requires a stable constitutional prompt that governs its behavior throughout the research workflow.
Main objective
Design a base system prompt that makes the orchestrator:
- role-disciplined
- skeptical of sub-agent outputs
- strict about workflow transitions
- strict about output format/schema compliance
- focused on correctness, provenance, and reliability over speed
The section frames this as an “Assume Breach” architecture, meaning every sub-agent output should be treated as potentially flawed until checked.
---
Core concepts
1. Identity and invariant constraints
The system prompt should immediately define the orchestrator’s identity.
It should establish that the orchestrator:
- is the master coordinator of a high-rigor research system
- prioritizes correctness, provenance, and reliability
- is read-only in role
- does not perform specialist work itself
- maintains workflow state and delegates tasks to sub-agents
This identity block is meant to prevent the model from drifting into a generic assistant role.
2. Capability map of specialist agents
The prompt should explicitly define each sub-agent’s role and boundaries.
Examples from the section:
- searcher = discovery only
- fetcher = extraction only
- analyst = synthesis only
- verifier = citation audit
- critic = adversarial review
The purpose is to:
- reduce role confusion
- improve delegation accuracy
- make expected outputs more predictable
- avoid overlapping responsibilities between agents
3. Hard phase-gate logic
The prompt should include explicit rules for when the orchestrator may or may not advance the workflow.
Instead of relying on vague judgment, the prompt should require concrete checks before phase transitions.
Example logic:
- before synthesis, confirm evidence exists
- confirm all evidence items have valid IDs
- halt the workflow if required conditions are not met
This makes the orchestrator act more like a procedural controller than a conversational assistant.
4. Schema enforcement and rejection behavior
The orchestrator should reject malformed or non-compliant sub-agent outputs.
If a specialist returns output that does not match the required schema, the orchestrator should:
- reject it
- issue a correction or retry request
- avoid repairing the payload itself unless explicitly allowed
This is intended to prevent malformed outputs from propagating downstream into memory, critique, or final writing stages.
5. Permanent constitution vs temporary instructions
A key architectural distinction in this section is:
- the system prompt holds permanent rules that always apply
- commands and skills add temporary, phase-specific or scenario-specific instructions
The system prompt should therefore contain only the rules that must remain stable across the full workflow:
- identity
- delegation map
- phase discipline
- output validation rules
- refusal/rejection behavior
6. Skeptical orchestration posture
The section promotes a skeptical orchestration style:
- do not trust sub-agent outputs by default
- verify before advancing
- reject unsupported or malformed outputs
- preserve provenance and structural integrity at every handoff
This is intended to reduce contamination, silent errors, and overly permissive orchestration behavior.
---
What this section is trying to achieve
This section is trying to create a master orchestrator that:
- behaves consistently over long research runs
- enforces specialist boundaries
- applies hard workflow controls
- maintains high-quality structured handoffs
- treats every output as something to validate, not automatically trust

## Tips for Defining The Research Pipeline
This section describes how the research orchestrator should run the full research workflow from start to finish.
At a high level, the orchestrator’s job is to:
- move the research through defined phases
- delegate each type of work to the right specialist agent
- validate outputs before advancing
- handle contradictions and missing evidence
- prepare a clean final handoff for report writing
Core idea
The orchestrator is the central workflow manager. It does not do all the research itself. Instead, it:
- plans the workflow
- launches specialist agents
- tracks evidence and state
- checks quality gates
- triggers retries or escalation when needed
- assembles final materials for the writer
High-level flow
1. Planning and discovery
After the research plan is approved, the orchestrator:
- initializes research state
- breaks the topic into workstreams
- launches search/discovery tasks for those workstreams
- combines and de-duplicates the results
2. Retrieval, synthesis, and verification
Next, the orchestrator:
- sends sources to a fetcher/extractor
- validates returned evidence
- stores evidence in structured form
- sends relevant evidence to an analyst for synthesis
- sends synthesized claims to a verifier to check citation support
If verification fails, the orchestrator may send the workflow back for more searching or retrieval.
3. Critique and resolution
After synthesis and verification, the orchestrator:
- sends findings to a critic for adversarial review
- checks for contradictions or weak support
- tries to resolve conflicts using evidence quality and other rules
- limits how many critique loops can occur
- pauses or escalates if issues remain unresolved
4. Final handoff and drafting
Once the findings are strong enough, the orchestrator:
- gathers the final state of evidence and conclusions
- prepares a structured handoff package
- sends that package to the writer agent
- uses the writer only after the evidence and critique steps are complete
What this section is trying to achieve
This section is trying to define a reliable execution model for deep research:
- parallelize where safe
- validate before trusting
- correct problems before they spread
- keep the workflow structured
- ensure the final report is based on checked evidence

## Improving the Agent Workflow for Accurate and Trustworthy Research
This section focuses on making a multi-agent research system more trustworthy during long, complex workflows. Its main concern is that even with a good architecture, the system can still fail through subtle forms of information distortion, weak evidence handling, or context degradation over time.
Main objective
Reduce the risk that the research workflow becomes less reliable as information moves across:
- agents
- phases
- summaries
- search results
- long context windows
The section is trying to prevent the system from becoming overconfident, contaminated, or structurally confused during deep research.
---
Core concepts
1. Prevent semantic laundering
Semantic laundering happens when a claim becomes trusted simply because it passed through a trusted part of the workflow, even if the original evidence was weak or distorted.
Key idea:
- the orchestrator should avoid rephrasing or “cleaning up” raw evidence before handing it to downstream agents
- downstream specialists should work from structured evidence, not from overly interpreted summaries
- missing or uncertain information should be rejected or flagged, not silently filled in
2. Preserve strict context boundaries
Different agents should not share the same mixed context.
The system should isolate:
- raw fetched material
- analytical synthesis
- critique/counterevidence
- final drafting context
This reduces contamination between stages and makes it less likely that one agent’s assumptions will silently influence another.
3. Control source quality and ranking bias
Search results can amplify plausible but low-quality sources. The system should not trust ranking alone.
The section recommends:
- labeling sources by tier and type
- checking whether evidence quality is strong enough for the claim type
- rejecting source sets that are dominated by weak or tertiary content
- requiring stronger sources for controversial, technical, or high-risk claims
4. Make the system resilient to context compaction
Long research runs will eventually stress the context window.
The section recommends:
- pruning low-value historical tool output
- reserving context space for active reasoning and synthesis
- storing important workflow state outside the active prompt/context
- retrieving state from persistent memory when needed
This reduces dependence on fragile conversational memory.
5. Treat reliability problems as structural, not just model problems
A major theme of the section is that many failures come from workflow design, not just from model weakness.
So mitigation should focus on:
- stronger boundaries
- cleaner handoffs
- better evidence discipline
- persistent state
- explicit rules for handling uncertainty and contradiction
---
What this section is trying to achieve
This section is trying to build a research system that:
- does not become more error-prone as it runs longer
- preserves evidence fidelity across handoffs
- avoids giving false confidence to weak claims
- resists contamination between specialist agents
- survives long-context degradation without losing core state

# Tools to Add
## Sql for evidence table
### Custom mcp server
Build a local evidence-ledger system for an AI research workflow using SQLite + a narrow local MCP server.
Goal
Create a robust, local, portable evidence store that works with:
- OpenCode
- Claude Code
- other MCP clients later
The system must keep the research evidence tree out of the model context while allowing the orchestrator to persist and retrieve structured evidence through a small, typed MCP tool surface.
High-level architecture
Implement:
1. SQLite database as the canonical evidence store
2. Local MCP server (stdio preferred) exposing narrow evidence-management tools
3. Optional convenience:
   - sample MCP client config for OpenCode / Claude Code
   - seed/init script
   - short usage docs
Do not build a generic SQL MCP server.  
Do not expose arbitrary SQL execution to the model.  
The MCP server must expose only the specific tools described below.
---
Core design requirements
Why SQLite
Use SQLite because this system needs:
- transactions
- relational integrity
- foreign keys
- constraints
- single local-file portability
- simple cleanup
Why narrow MCP tools
The LLM should not manage SQL directly.  
Instead, it should call high-level operations like:
- create task
- add source
- add excerpt
- add finding
- retrieve handoff bundle
- cleanup task
This reduces:
- prompt injection risk
- malformed SQL
- schema drift
- tool/context bloat
---
Storage model
Prefer one SQLite database per task.
Recommended path pattern:
- .opencode/state/tasks/<task_id>.sqlite
If implementation simplicity strongly favors a single DB with task_id columns, that is acceptable, but per-task DB files are preferred for:
- hard isolation
- trivial cleanup
- easier debugging
---
Required schema
Implement a relational evidence graph with these entities:
1. sources
Stores accepted sources.
Suggested fields:
- source_id primary key
- citation_id integer, stable within task
- url text, required
- title text
- source_tier text
- source_type text
- content_ref text
- content_hash text
- metadata_json text or JSON
- timestamps
Constraints:
- unique citation id per task/db
- unique url if appropriate
2. excerpts
Stores cited excerpts from sources.
Suggested fields:
- excerpt_id primary key
- source_id foreign key
- locator text
- excerpt_text text, required
- excerpt_hash text
- metadata_json
- timestamps
3. findings
Stores analyst claims.
Suggested fields:
- finding_id primary key
- workstream text
- claim_text text, required
- strength text
- status text
- payload_json
- timestamps
Allowed values:
- strength: strong | moderate | weak | contested
- status: draft | supported | unsupported | contested | revised | final
4. finding_evidence
Join table between findings and excerpts.
Suggested fields:
- finding_id foreign key
- excerpt_id foreign key
- relation text
Allowed values:
- relation: supports | contradicts | context
5. verification_reports
Stores verifier audits.
Suggested fields:
- verification_id primary key
- finding_id foreign key
- verdict text
- notes_json
- timestamps
Allowed values:
- verdict: supported | unsupported | misattributed | unverifiable
6. contradictions
Stores critique-loop contradiction records.
Suggested fields:
- contradiction_id primary key
- finding_id foreign key nullable
- contradiction_text text
- resolution_status text
- payload_json
- timestamps
Allowed values:
- resolution_status: open | investigated | resolved | dismissed
Requirements
- enable foreign keys
- add useful indexes
- enforce allowed values with CHECK constraints where possible
- use transactions for multi-step write operations
- make schema deterministic and easy to inspect
---
MCP server requirements
Implement a local stdio MCP server.
Preferred language:
- choose the language/ecosystem that leads to the most maintainable result
- TypeScript/Node or Python are both fine
Important
Expose a narrow typed toolset only.  
Do not expose a raw SQL execution tool.
Required MCP tools
Task lifecycle
1. create_task
- input: task_id, objective
- behavior:
  - create the task SQLite DB if per-task
  - initialize schema if needed
  - return success metadata
2. cleanup_task
- input: task_id
- behavior:
  - delete task-local DB file if per-task
  - return cleanup result
Source ingestion
3. add_source
- input:
  - task_id
  - workstream
  - url
  - title
  - source_tier
  - source_type
  - content_ref optional
  - metadata_json optional
- behavior:
  - assign next stable citation_id
  - insert source
  - return source_id, citation_id
4. add_excerpt
- input:
  - task_id
  - source_id
  - locator
  - excerpt_text
  - metadata_json optional
- behavior:
  - insert excerpt
  - return excerpt_id
Synthesis
5. add_finding
- input:
  - task_id
  - workstream
  - claim_text
  - strength
  - status
  - payload_json optional
- behavior:
  - insert finding
  - return finding_id
6. link_finding_excerpt
- input:
  - task_id
  - finding_id
  - excerpt_id
  - relation
- behavior:
  - create join row
  - return success
Verification / critique
7. record_verification
- input:
  - task_id
  - finding_id
  - verdict
  - notes_json
- behavior:
  - insert verification report
  - optionally update finding status if appropriate
  - return verification id and updated status
8. record_contradiction
- input:
  - task_id
  - finding_id optional
  - contradiction_text
  - resolution_status
  - payload_json optional
- behavior:
  - insert contradiction row
  - return contradiction id
9. update_finding_status
- input:
  - task_id
  - finding_id
  - status
- behavior:
  - update finding status
  - return updated row metadata
Retrieval
10. get_task_stats
- input: task_id
- output:
  - counts for sources, excerpts, findings, verifications, contradictions
  - number of unresolved/open contradictions
  - number of supported/final findings
11. get_finding_bundle
- input:
  - task_id
  - finding_id
- output:
  - finding metadata
  - linked excerpts
  - linked citation ids
  - minimal source metadata
- output should be compact and optimized for token efficiency
12. get_handoff_bundle
- input:
  - task_id
- output:
  - finalized findings only
  - strengths/statuses
  - linked citations [n]
  - compact supporting excerpts
  - unresolved contradictions / limitations summary
- this should be the main writer-facing retrieval tool
---
Behavior requirements
Token efficiency
Design retrieval tools so they return:
- compact bundles
- IDs
- short excerpts
- minimal source metadata
Do not return:
- full documents
- every row in the DB unless explicitly needed
- raw content blobs
Safety
- validate all inputs
- enforce enums/allowed values
- do not allow arbitrary SQL
- do not allow arbitrary file paths outside the task-state directory
- ensure task IDs are sanitized if used in file paths
Reliability
- use transactions
- return structured errors
- gracefully handle duplicate URLs / invalid foreign keys / missing tasks
- include tests if practical
---
Files / deliverables to create
Create a clean project structure with at least:
1. SQLite schema/init logic
2. MCP server implementation
3. README explaining:
   - architecture
   - why SQLite + narrow MCP
   - how to run locally
   - how to connect from OpenCode
   - how to connect from Claude Code
   - example tool usage in a research workflow
4. Example client configuration
Provide example MCP config snippets for:
- OpenCode
- Claude Code
5. Example workflow
Include a short example showing:
- create task
- add source
- add excerpt
- add finding
- link evidence
- record verification
- get handoff bundle
- cleanup
---
Research-workflow mapping
The system should map to this style of pipeline:
- Phase 2: create_task
- Phase 4: add_source, add_excerpt
- Phase 5: add_finding, link_finding_excerpt
- Phase 5b: record_verification
- Phase 6: record_contradiction, update_finding_status
- Phase 8: get_handoff_bundle
- Phase 9: cleanup_task
---
Implementation preferences
- prioritize correctness and maintainability over cleverness
- keep dependencies minimal
- prefer readable code
- use clear types/schemas
- document tradeoffs
If a design choice must be made, prefer:
1. portability across MCP clients
2. safety
3. inspectability
4. low operational complexity
---
Final output expected from you
When done, provide:
1. a summary of the architecture you implemented
2. the file tree
3. key schema decisions
4. the exposed MCP tools
5. how to run it locally
6. example OpenCode / Claude Code config
7. any limitations or follow-up recommendations

### Implementation with Research Agent
Help me set up a local custom MCP server for my OpenCode-based research agent.
Context
I am building a research workflow where the agent needs a durable local evidence ledger outside the model context. I have decided to use:
- SQLite as the local database
- a narrow local MCP server as the interface
- OpenCode as the primary client/runtime
- possibly Claude Code later, so the setup should remain MCP-compatible and portable
I do not want arbitrary SQL exposed to the model.  
I want a small, typed tool surface for evidence management.
---
What I need from you
Please help me set up this new MCP server in my OpenCode environment.
I want you to explain and generate the setup for:
1. How the MCP server should be added to OpenCode
2. What the OpenCode config should look like
3. What permissions should be configured
4. How the agent should be instructed to use the MCP tools
5. How to keep the MCP setup lightweight so it does not waste context tokens
6. How to make the setup easy to reuse later in Claude Code or other MCP clients
---
Desired architecture
Assume I will have a local MCP server that exposes only these kinds of tools:
- create_task
- cleanup_task
- add_source
- add_excerpt
- add_finding
- link_finding_excerpt
- record_verification
- record_contradiction
- update_finding_status
- get_task_stats
- get_finding_bundle
- get_handoff_bundle
This MCP server will be responsible for managing a local SQLite evidence database.
---
OpenCode-specific setup goals
Please show me how to configure OpenCode so that:
- the MCP server is loaded locally
- the tool names are clear and scoped
- the permissions are safe
- the orchestrator can use the MCP tools during research
- the MCP server does not overload the agent with unnecessary tools
I want OpenCode configured so that:
- built-in editing tools can still be controlled separately
- the MCP server can be allowed or permission-gated explicitly
- only this one local evidence MCP is added, not a large number of unrelated MCP servers
---
What to produce
Please give me:
1. Recommended OpenCode config structure
Show how the config should conceptually include:
- the MCP server registration
- any plugin/custom-tool considerations if relevant
- permissions for the MCP tools
Use short example config snippets, not excessively detailed production configs.
2. Recommended file layout
Show where things should live conceptually, for example:
- MCP server project directory
- local SQLite state directory
- OpenCode config
- optional skills/instructions files
3. Agent instructions
Give me text I can place into:
- AGENTS.md
- OpenCode instructions
- or project-local skills
These instructions should teach the agent:
- the evidence ledger is the source of truth
- never keep the whole evidence table in prompt context
- persist evidence as it is accepted
- retrieve only compact bundles
- use get_handoff_bundle for final writing
4. Minimal workflow example
Show a short example of how the agent should use the tools in a real session:
- create task
- add source
- add excerpt
- add finding
- verify
- retrieve handoff bundle
5. Token-efficiency guidance
Explain how to keep the MCP setup lean in OpenCode:
- avoid too many tools
- avoid generic SQL
- avoid returning full source documents
- prefer compact retrieval responses
6. Portability guidance
Explain how to structure this so that later I can also use the same MCP server in:
- Claude Code
- other MCP-compatible clients
---
Constraints
- Keep the setup local-first
- Prefer stdio MCP if that is the simplest and most portable option
- Do not introduce unnecessary infrastructure
- Do not recommend generic SQL access
- Prioritize safety, simplicity, and portability
---
Output style
I want a practical setup guide aimed at implementation, with:
- concise explanation
- short config examples
- recommended structure
- recommended agent instructions
Do not focus on building the database itself here.  
Focus on how to wire the MCP server into OpenCode and how the agent should use it correctly.

## Knowledge Memory Graph Server
Create a complete Knowledge Graph MCP configuration for a research agent system with the following specifications:
**MCP Server to Use:**
- Package: @modelcontextprotocol/server-memory
- Type: Official Anthropic reference implementation
- Stars: 79.7k+
- Installation: npx -y @modelcontextprotocol/server-memory
**Configuration Requirements:**
1. OpenCode Configuration (opencode.json):
   - MCP server name: "research-memory"
   - Command: npx -y @modelcontextprotocol/server-memory
   - Environment variable: MEMORY_FILE_PATH = "./research-tasks/current-task.json"
   - Must support task isolation via different file paths per research task
2. Entity Schema (define these entity types):
   - source: Evidence sources (URLs, documents, CVEs)
     - Observations: url, tier (1/2/3), content, fetched_at
   - finding: Analyst synthesis/claims
     - Observations: claim, confidence ([strong]/[moderate]/[weak]/[contested]), workstream, evidence_refs
   - contradiction: Conflicting claims
     - Observations: claim_a, claim_b, resolution, status
   - workstream: Research topic areas
     - Observations: topic, status, priority
3. Relation Schema (define these relation types):
   - supports: finding -> source (evidence supports claim)
   - contradicts: finding -> finding (claims conflict)
   - belongs_to: finding -> workstream (organization)
4. Agent Usage Instructions:
   - Phase 4 (Retrieval): Create source entities for each fetched URL
   - Phase 5 (Synthesis): Create finding entities with confidence tags
   - Phase 6 (Critique): Create contradiction entities for conflicts
   - Phase 8 (Handoff): Use read_graph to get complete context
5. Naming Conventions:
   - Sources: source_{type}_{number} (e.g., source_nvd_001)
   - Findings: finding_{workstream}_{topic} (e.g., finding_auth_bypass)
   - Contradictions: contradiction_{number} (e.g., contradiction_001)
6. Required Tools to Document:
   - create_entities: Store new sources/findings
   - create_relations: Link findings to sources
   - add_observations: Add details to existing entities
   - search_nodes: Find relevant information by query
   - read_graph: Get complete research context
   - delete_entities: Cleanup after task completion
7. Task Isolation Strategy:
   - Each research task uses unique MEMORY_FILE_PATH
   - Format: ./research-tasks/task-{id}.json
   - Cleanup: Delete file after research completes
Provide:
- Complete opencode.json configuration
- AGENTS.md usage section
- Example code for each phase (4, 5, 6, 8)
- File cleanup instructions