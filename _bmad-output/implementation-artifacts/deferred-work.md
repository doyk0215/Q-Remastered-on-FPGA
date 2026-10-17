- source_spec: `_bmad-output/specs/spec-q-remastered-on-fpga/stories/3-implement-bounded-rigid-body-arithmetic-and-motion.md`
  summary: Strengthen the existing BMAD setup check to probe renderer support files and the usable Python interpreter rather than reporting only uv/SKILL.md discovery.
  evidence: Build review BH-9 confirmed the pre-existing main-branch setup checker prints Python as a descriptive string and does not execute an interpreter or validate the renderer/support-file paths; a future teammate could receive an incomplete readiness result. This is onboarding maintenance, separate from Story 3 physics.

- source_spec: `_bmad-output/specs/spec-q-remastered-on-fpga/stories/3-implement-bounded-rigid-body-arithmetic-and-motion.md`
  summary: Refresh the AGENTS.md sentence claiming no application consumers of the adopted draft headers after the Story 3 implementation.
  evidence: Build review BH-10 confirmed q_path_length and the numerical modules now consume these headers. Build's review routing defers agent-context changes to explicit context maintenance; no ownership or approval rule is changed by this physics implementation.
