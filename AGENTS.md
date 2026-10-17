# Q Remastered — instructions for coding agents

## Start here

This is a Basys3 FPGA game in application Verilog-2001, with supplied VHDL behind adapters. Read [the teammate guide](docs/TEAMMATE-GUIDE.md), [approval/start checklist](docs/parallel-start-checklist.md), your assigned story and its linked designs before implementation. Repository files, not another developer's chat history, are the shared context.

The user approved the initial isolated parallel builds on 2026-10-17, recorded in `418ea42`. Do not restart the brief/PRD/architecture, replan all stories, or ask to repeat that approval merely because older draft paragraphs say pending. Completion review and actual behavioral/resource/timing/board evidence are still required. Short provisional previews are approved; final admission still requires the shared computed length >=16 pixels.

## Identify the assignment and use a branch

Do not infer the human's identity from the OS account, BMAD config defaults or Git author. If no name/story is supplied, ask once before choosing another person's work.

| Human | First story | Branch | Principal scope |
| --- | --- | --- | --- |
| Han Qi-Ze | 6 | `codex/story-6-input` | `rtl/input/`, controller/input wrapper, capture and gestures |
| Kim Doyeon | 3 | `codex/story-3-physics` | Shared length kernel under `rtl/common/`, `rtl/physics/`, numerical foundation |
| Chua Choon Hsiang | 2 | `codex/story-2-rendering` | `rtl/graphics/`, framebuffers, rasterization and transfer; platform follow-up |

Use `git status` first; preserve all existing work. Start a new assignment from clean, updated `main` with `git pull --ff-only`, then `git switch -c <assigned-branch>`. If that branch already exists, inspect and resume it; never reset/recreate it with `-C`. Later stories use `codex/story-<id>-<description>`. Separate developers/agents need separate checkouts/worktrees and explicit assignments. Run `node scripts/team/check_workflow.mjs --story <id>` before implementation and handoff.

Feature work never commits/pushes directly to `main`. Push only the assigned feature branch when the human authorizes publication, using `git push -u origin <branch>`. Open a PR targeting `main` when available; otherwise provide the branch/compare link and handoff. Qi-Ze coordinates merge order; do not merge, force-push, rewrite shared history, delete work or resolve another owner's contract change without authorization. Explicitly requested coordinator maintenance (team setup/docs/BMAD runtime) may use `team`/`bmad` scope; that exception does not authorize feature changes on main.

## Commits and reviews

Use focused conventional subjects: `feat(story-6): retain stroke endpoints during simplification`, `fix(story-3): preserve fractional gravity`, `test(story-2): cover stale frame release`. Allowed types: feat, fix, test, docs, refactor, chore, build, ci. Story scope must match the active branch. Maintenance uses e.g. `chore(team): verify local setup` or `docs(bmad): clarify bootstrap`. Use the human's configured Git identity; do not copy another teammate's email or set global identity. If absent, ask the human to configure it.

Inspect/stage explicit files and review the staged diff; never bundle another person's work or generated outputs. Do not create empty commits or claim unrun checks. Each PR/handoff states story, behavior changed, actual verification, known limitations and cross-owner dependencies. A passing reference checker alone never marks an HDL story done. Preserve the story queue's spec/done checkpoints and obtain the named completion review; never impersonate a human reviewer.

## BMAD workflow and local setup

The tracked configuration pins BMAD **6.12.2**. Runtime files/IDE skills are generated locally by `node scripts/team/setup_bmad.mjs --name "Your name"` and are ignored by Git. Do not upgrade/migrate BMAD, rerun the full installer or overwrite `_bmad-output/` to recover missing skills. Install prerequisites from the guide; `uv` and Python >=3.11 are needed by the actual workflows. `node scripts/team/setup_bmad.mjs --check` verifies discovery/prerequisites. Restart/reopen the AI project after generating skills.

Use `bmad-build` for the explicitly assigned existing story, and `bmad-code-review`/`bmad-walkthrough` when appropriate. The sequential `stories.yaml` order is a backlog, not authority to seize Story 1 or another developer's next story. Select 2/3/6 explicitly. Read the installed SKILL.md and execute its renderer exactly; if prerequisites/rendering fail, report the concrete error and repair setup, rather than pretending BMAD ran or executing raw placeholder templates. Other tools should explicitly read this file and `.agents/skills/bmad-build/SKILL.md` if they do not discover them automatically.

Do not edit installer-managed `_bmad/config.toml`. Team overrides are `_bmad/custom/`; personal names/settings belong in ignored `_bmad/custom/config.user.toml`. A local customization must not silently weaken shared ownership/checkpoints. Existing approvals govern the initial story plans; if a material contract/scope change needs a new human decision, prepare the concrete change first and explain that specific decision.

## Boundaries that must remain consistent

Controller alone owns mode/allowance/attempt IDs; physics owns accepted bodies/world revisions; input owns provisional capture; graphics owns completed presentation/bank ownership. All owners consume shared definitions. Coordinate shared headers/layout/length changes before merging consumers. Choon Hsiang maintains top/build/pins; Qi-Ze coordinates integration. Never privately duplicate numerical or hit-region constants.

The three additive `*_draft.vh` headers are adopted initial definitions despite their retained filenames; no application RTL implements them yet. Public packed records remain revision 2. Follow the exact approved wiring, length/rounding, simplifier, memory/pipeline and mailbox designs. Do not change units, message packing, radius/length limits, handshake/reset semantics or source provenance independently.

Use `.gitattributes` and preserve the 15 baseline source hashes in `hardware/source-manifest.json`. Do not edit supplied drivers or change hashes to bless accidental edits. Build into ignored `build/`; never commit Vivado output/cache, `.agents/skills`, generated BMAD runtime/snapshots, personal config or credentials.

## Verification and handoff commands

From the project root (portable tool names, not another developer's absolute paths):

```sh
node scripts/team/setup_bmad.mjs --check
node scripts/team/check_workflow.mjs --story 6
node scripts/planning/validate_parallel_plan.mjs
vivado -mode batch -log build/planning_headers.log -source scripts/planning/check_headers.tcl
vivado -mode batch -source scripts/vivado/create_project.tcl -tclargs JB
vivado -mode batch -log build/verify_foundation.log -source scripts/vivado/verify_foundation.tcl
```

Replace 6 with the actual story. Run checks appropriate to changed behavior, including meaningful HDL verification for implemented logic. A legacy Story 1 note disallowing unrequested tests describes its prior execution; it is not a repository-wide prohibition on tests authorized by an implementation assignment. The existing reference checker tests design models, not RTL. Vivado is required for HDL/build checks; record it as unavailable if missing. Project creation overwrites generated build output; preserve needed evidence first. Do not repeat full routing for prose-only changes.

Target Vivado 2025.2 / xc7a35tcpg236-1. JB is the planned OLED header; wiring is unconfirmed. Four CDC findings, reset/input behavior and actual peripheral acceptance remain open. Isolated approved blocks may be built with controlled inputs/clocks; real scanout/peripheral acceptance and final board claims require their gates. Do not claim the game, 60 Hz worst-case performance or a board-tested release exists yet. Do not program a board or publish a release without the relevant human authorization.
