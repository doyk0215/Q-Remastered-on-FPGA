# Q Remastered on FPGA

A Basys3 FPGA drawing-and-physics puzzle game, inspired by Q REMASTERED. The project uses the BMad Method to organize requirements, architecture, and implementation work.

## BMad setup

BMad Method **6.12.2** configuration and project plans are tracked here. Restore the local runtime/skills with `node scripts/team/setup_bmad.mjs --name "Your name"`, then reopen your AI project. Start with the [concise teammate guide](docs/TEAMMATE-GUIDE.md); agents must read [AGENTS.md](AGENTS.md). Skills are generated under `.agents/skills/` and plans remain under `_bmad-output/`. Select your assigned story explicitly rather than starting the sequential backlog again.

## Project brief

See [`docs/project-brief.md`](docs/project-brief.md) for the current scope and constraints.

## Parallel development handoff

Start with [the parallel start checklist](docs/parallel-start-checklist.md) for assignments, adopted designs, shared declarations, validation commands and the recorded user approval. Stories 2, 3 and 6 may begin isolated implementation; completion review and CDC/board acceptance remain open.

## Basys3 foundation and evidence

See [`docs/hardware-bringup.md`](docs/hardware-bringup.md) for the Vivado 2025.2 creation command, required OLED header argument, wiring, interfaces and pending hardware evidence. Imported source identities and notices are recorded in [`hardware/source-manifest.json`](hardware/source-manifest.json).
