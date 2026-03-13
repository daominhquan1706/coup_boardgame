---
name: analyze-project-required-skills
description: 'Analyze a codebase and list the skills needed to build and maintain it. Default output is a bilingual (VI/EN) learning roadmap with file-level evidence. Use for requests like check source code, list required skills, stack assessment, hiring profile, learning roadmap.'
argument-hint: 'Project context and preferred output depth. Default: bilingual learning roadmap + file-level evidence.'
---

# Analyze Project Required Skills

Produce an evidence-based skill matrix and learning roadmap for the current project by inspecting real source files, architecture, and runtime workflow.

## When To Use
- User asks to check source code and list required skills.
- User needs a hiring profile for this project.
- User wants a learning roadmap tailored to the current repository.
- User asks which skills are core vs optional for the team.

## Inputs To Confirm
1. Output goal: learning roadmap, hiring matrix, or both.
2. Scope: full repository or specific module.
3. Depth: quick, medium, or thorough.
4. Preferred language: Vietnamese, English, or bilingual.
5. Evidence level: file-level or line-level.

If user did not specify, default to full repository, medium depth, bilingual (VI/EN), learning-roadmap-first output, and file-level evidence.

## Procedure

### Step 1. Load Mandatory Instructions
1. Read workspace instruction files that are required by environment rules.
2. Apply those rules before scanning the repository.

Completion check:
- Confirm all required instruction files were loaded before analysis.

### Step 2. Build A Stack Snapshot
1. Read top-level project signals such as README and dependency manifest.
2. Identify framework, state management, backend services, tooling, and platforms.
3. Record concrete evidence paths for each claim.

Completion check:
- At least 3 stack claims with file evidence.

### Step 3. Inspect Architecture And Runtime Flow
1. Read route setup and app entry.
2. Read key modules: page, controller, binding, provider/service, model.
3. Read technical docs if present: business rules, schema, flow diagrams.
4. Identify where core business logic actually runs.

Completion check:
- Evidence collected from both code and docs.
- Core logic owner identified (UI layer, service layer, backend layer, or mixed).

### Step 4. Derive Skill Matrix With Decision Branches
Use these branches to avoid generic output:

1. If realtime backend operations and transactions are central:
- Add concurrency consistency and conflict-safe state transition skills.

2. If game or rules-based logic exists:
- Add domain modeling and state-machine skills.

3. If architecture uses GetX-like modular pattern:
- Add module lifecycle, DI/binding, reactive state granularity skills.

4. If generated models or codegen exist:
- Add build_runner or equivalent model-generation workflow skill.

5. If multilingual UI exists:
- Add i18n/l10n maintenance skill.

6. If test coverage is weak or missing:
- Mark testing as a risk and include testing skill as priority uplift.

### Step 5. Rank By Priority
Output skills in these buckets:
1. Core required.
2. High-impact advanced.
3. Nice-to-have.

For each skill include:
1. Why it is needed in this repo.
2. Evidence path from codebase (file-level).
3. Typical tasks it supports.

### Step 6. Provide Role And Learning Views
1. Convert matrix to phased roadmap by default (week-by-week or phase-by-phase).
2. Convert matrix to team roles only when user asks hiring angle.
3. In bilingual mode, provide each section as:
- VI: concise actionable guidance.
- EN: equivalent summary with same structure.

## Output Format
Use this structure:
1. Stack summary (short).
2. Core required skills.
3. High-impact advanced skills.
4. Nice-to-have skills.
5. Learning roadmap (default section, phased).
6. Team role mapping (optional, only if requested).
7. Risks and gaps.
8. Optional next steps.

## Quality Criteria
- Evidence-based: each major claim tied to existing file paths (file-level evidence only unless user asks line-level).
- Project-specific: avoid generic mobile checklist wording.
- Prioritized: clear Must, Should, Could separation.
- Actionable: include what each skill enables.
- Honest gaps: explicitly call out missing tests or security controls.
- Bilingual consistency: VI and EN sections should carry equivalent meaning and priority.

## Example Prompts
- Analyze this source code and list the skills required to build and maintain it.
- Based on this repo, create a hiring skill matrix for 3 engineers.
- Check this project and produce a 4-week learning roadmap of required skills.
- Analyze this codebase and return bilingual (VI/EN) skill requirements with file-level evidence.
