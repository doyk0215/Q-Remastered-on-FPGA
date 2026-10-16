# Q Remastered on FPGA

A Basys3 FPGA drawing-and-physics puzzle game, inspired by Q REMASTERED. The project uses the BMad Method to organize requirements, architecture, and implementation work.

## BMad setup

BMad Method v6.12.2 is installed in this repository, with Codex skills under `.agents/skills/`. Start Codex in this folder and use the `bmad-help` skill to choose the next workflow. Shared planning artifacts are saved under `_bmad-output/`.

## Project brief

See [`docs/project-brief.md`](docs/project-brief.md) for the current scope and constraints.

## Basys3 foundation

See [`docs/hardware-bringup.md`](docs/hardware-bringup.md) for the Vivado 2025.2 creation command, required OLED header argument, wiring, interfaces and pending hardware evidence. Imported source identities and notices are recorded in [`hardware/source-manifest.json`](hardware/source-manifest.json).
