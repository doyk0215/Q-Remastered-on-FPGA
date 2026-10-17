# Team onboarding validation — 2026-10-17

Validated a fresh export of the staged repository in an isolated Git checkout on Windows. No application RTL changed.

- Pinned BMAD 6.12.2 package integrity verified; setup restored 464 runtime/skill/license files and discovered all 29 skills.
- Repeated setup wrote zero files and retained the existing personal override.
- Config resolver returned the supplied teammate name, Han Qi-Ze, rather than the project author's default.
- Official `uv run --no-cache ...render_skill.py` command rendered `bmad-build` successfully. Its snapshot included AGENTS.md, ownership, start checklist and the explicit assignment/approval facts. Workflow implementation steps were not executed.
- Branch checker passed on `codex/story-6-input`. Three automated test groups passed for the initial assignments, main/detached branch rejection, matching scopes and malformed subjects.
- Actual Git commit-message hook accepted a Story 6 subject on the Story 6 branch and rejected a Story 3 subject there.
- Existing 12,438 reference/design checks passed, including all 15 baseline source hashes, in both the working checkout and fresh export. These are not RTL simulation or board acceptance.

Tests used Node 24.19.0, a locally staged uv 0.13.1 executable and the bundled Python interpreter. Teammates must install the documented prerequisites on their computers; their actual AI sessions and Vivado installations have not been tested. Skill discovery requires reopening the AI project. Other AI tools may need explicit instruction to read AGENTS.md and the skill entry point. The optional local hook enforces commit subjects, not server-side branch protection or AI compliance.

Repeat the portable checks from the repository root:

```sh
node scripts/team/setup_bmad.mjs --check
node --test scripts/team/check_workflow.test.mjs
node scripts/team/check_workflow.mjs --story 6
node scripts/planning/validate_parallel_plan.mjs
```

Use the actual assigned story for the branch check. See [the teammate guide](../TEAMMATE-GUIDE.md) for setup and first-run instructions.
