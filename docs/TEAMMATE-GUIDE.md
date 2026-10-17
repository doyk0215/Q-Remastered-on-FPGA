# First-time BMAD guide — Q Remastered

BMAD gives the AI a repeatable workflow: **read the approved story → implement → verify → review → hand off**. It does not replace Git, Vivado or our decisions. You do not need to redo project planning. AI chat history on another computer is not shared; the files in this repository are our shared memory.

## Where we are

- Brief, PRD, UX, architecture, shared contracts and the 12-story backlog are prepared.
- The initial designs and before-coding checkpoints for Stories **2, 3 and 6** were approved on 17 October 2026. Headers whose filenames end in `_draft.vh` are adopted initial definitions; their hardware behavior is not yet implemented/proven.
- Vivado 2025.2 project creation, synthesis, routing and foundation timing passed. This is a peripheral/platform foundation, **not a working game**. Four CDC findings and real board/peripheral checks remain open. OLED is planned for **JB**; actual wiring is unconfirmed.
- Build the approved isolated subsystems now. Do not mark a story done merely because files exist or the planning checker passes.

## 1. Get your own checkout and tools

Install Git, Node.js **20.12+**, and [uv](https://docs.astral.sh/uv/getting-started/installation/). BMAD's renderer needs Python **3.11+**; uv can manage that interpreter. Install **Vivado 2025.2** for HDL/build checks. Missing Vivado need not block reading/planning, but the AI must report checks it cannot run.

```sh
git clone https://github.com/doyk0215/Q-Remastered-on-FPGA.git
cd Q-Remastered-on-FPGA
node scripts/team/setup_bmad.mjs --name "Han Qi-Ze" --hooks
```

Replace the name with yours. This restores the official **BMAD 6.12.2** runtime/skills from an integrity-pinned package, keeps project plans intact, sets a local ignored name override and enables the optional commit-message hook. Do not install “latest”, migrate to v7 or regenerate our project. Ensure your own Git author name/email are configured. Setup files and personal settings stay out of commits.

Restart/reopen your AI project after setup so it can discover the skills. In Codex, open this repository folder. For another AI tool, explicitly tell it to read `AGENTS.md` and `.agents/skills/bmad-build/SKILL.md`; if it uses another project skill directory, setup accepts `--skills-dir <project-skill-folder>`. Do not assume every tool reads AGENTS automatically.

## 2. Start only your assigned story

| Developer | Work now | Branch | First deliverable |
| --- | --- | --- | --- |
| Han Qi-Ze | [Story 6](../_bmad-output/specs/spec-q-remastered-on-fpga/stories/6-capture-mouse-gestures-and-the-visible-stroke-preview.md) — input | `codex/story-6-input` | Capture/simplifier and input wrapper |
| Kim Doyeon | [Story 3](../_bmad-output/specs/spec-q-remastered-on-fpga/stories/3-implement-bounded-rigid-body-arithmetic-and-motion.md) — physics | `codex/story-3-physics` | Shared length kernel, then arithmetic/motion |
| Chua Choon Hsiang | [Story 2](../_bmad-output/specs/spec-q-remastered-on-fpga/stories/2-render-coherent-buffered-vga-scenes.md) — graphics | `codex/story-2-rendering` | Framebuffer banks and capsule span engine |

Copy this starter prompt and substitute your row:

> Read AGENTS.md and docs/parallel-start-checklist.md. I am Han Qi-Ze, assigned Story 6 on codex/story-6-input. Use bmad-build for that existing approved story, not automatic next-story selection. Create or resume my branch, implement its approved isolated scope, and run the relevant checks. You may make focused story-scoped commits and push my branch for review. Preserve other work, coordinate shared interfaces, report missing tools honestly, and do not merge main or claim board acceptance. Show the changed behavior, verification and remaining work when handing off.

The AI should first report your story/branch and read its dependencies. `bmad-help` is for orientation, `bmad-build` implements the selected story, and `bmad-code-review`/`bmad-walkthrough` help review. Do not ask for generic “next story”: the queue is sequential, but our three assignments intentionally run in parallel.

## 3. Commit, push and hand off

Use small commits with meaningful subjects, e.g. `feat(story-6): preserve stroke endpoints`, `fix(story-3): retain substep gravity precision`, `test(story-2): cover stale frame rejection`. The optional hook checks subject/branch agreement. Do not commit Vivado output, installed skills or personal config.

Publish **your branch**, open a PR to `main` (or give Qi-Ze the branch link), and include behavior changed, checks actually run and known limitations. Qi-Ze coordinates merges; Choon Hsiang coordinates top/build changes. Shared length/layout/header changes must be agreed before their consumers diverge. Bring blockers back to the team instead of privately changing the common contract.

## What follows

1. Build/review Stories 2/3/6; Doyeon continues physics Stories 4/5.
2. Story 7 joins drawing, admission, physics, display and goal detection into the first playable slice.
3. Stories 8–10 complete navigation, status and the three stage solutions.
4. Story 11 collects real integrated board/timing/resource evidence; Story 12 packages and rehearses the assessed release.

Exact demo/submission dates still need confirmation; the recorded demo context is Week 13, about 2–5 minutes. See the [full plan](parallel-development-plan.md) and [start checklist](parallel-start-checklist.md) when you need detail.

Setup references: [official BMAD installation/version guidance](https://docs.bmad-method.org/start/install-bmad/), [OpenAI repository instructions](https://developers.openai.com/codex/guides/agents-md), [OpenAI skill discovery](https://developers.openai.com/codex/skills). Our pinned recovery avoids mixing the current v7 documentation with this v6.12.2 project.
