---
title: "Product Brief: Q Remastered on FPGA"
status: complete
created: 2026-10-14
updated: 2026-10-15
---

# Product Brief: Q Remastered on FPGA

## Executive Summary

Q Remastered on FPGA is a drawing-and-physics puzzle game for the Basys3 development board, inspired by Q REMASTERED. A player draws a limited number of strokes; those strokes become physical objects that can redirect a ball toward the left display boundary. The first version focuses on a small, replayable puzzle loop that can be understood and demonstrated directly on the board.

The VGA display presents the stage lobby and full gameplay view. The Pmod OLED presents the current stage, objective, drawing budget, and status. A wired Logitech mouse supplies all game input; Basys3 buttons and switches are not used for game interaction, as course staff approved mouse-only input. LEDs indicate state. All gameplay is integrated into one bitstream and designed around the FPGA's resource limits.

## The Problem

[ASSUMPTION] The experience this game is designed to improve is the player's ability to influence a puzzle rather than only watch fixed obstacles. Drawing offers a simple way to change the ball's path. The project also explores whether this interaction can remain clear and responsive on a resource-limited FPGA.

## The Solution

The player chooses a stage from a VGA lobby, draws within a limited budget, and releases a stroke for validation. A valid stroke becomes a movable rigid body; a stroke penetrating the ball, an existing stroke, or a fixed obstacle is rejected without consuming allowance. The sampled polyline stroke responds to gravity, collisions, and angular motion, along with the ball and fixed obstacles. The player can pause, reset, continue to the next stage after a win, or return to the lobby without reprogramming the board. The OLED presents supporting stage and status information.

## What Makes This Different

The project combines mouse-based drawing, a simplified physics puzzle, and an integrated FPGA implementation. The player-created geometry is part of the puzzle solution, and the game presents its controls and status across the Basys3, VGA monitor, and Pmod OLED. The intended distinction is the interactive hardware experience and integration, rather than a claim of novel physics.

## Who This Serves

[ASSUMPTION] The primary user is a player trying a puzzle during a live demonstration; EE2026 assessors are a secondary audience who need to see the system's capabilities quickly. Both need clear controls, visible feedback, and a reliable path from level start to retry or victory.

## Success Criteria

- A player can select or start a level, draw and release an object, and observe the ball respond.
- At least one level can be completed by guiding any part of the ball into contact with the clearly indicated left display boundary.
- Pause and retry work without reprogramming the FPGA, and the integrated game remains responsive during a demonstration.
- VGA gameplay, OLED information, and LEDs communicate the game state clearly.
- The demonstrated capabilities run together in one bitstream within FPGA resource limits.

These criteria align with the course evaluation areas: functionality, robustness and reliability, user interface, and user experience.

## Scope

The first version includes three selectable stages, each with one ball, a five-stroke allowance per attempt, up to eight predefined fixed platforms or sloped ramps, and the full left display boundary as the goal. Each fixed platform or ramp is represented by a static capsule. At most six moving bodies are active: one ball and five released strokes. It uses fixed-point physics for gravity, movement, collisions, and visible rotation of released strokes. Use at most eight sample points per stroke as a provisional architecture profile, subject to synthesis and timing analysis; exact hardware interfaces remain open.

## Vision

[ASSUMPTION] If the core loop works well, the game can grow into a compact collection of puzzles that introduce new obstacle layouts or drawing challenges while preserving quick retries and reliable on-board play. Future additions should deepen the same drawing-and-physics experience and remain within the FPGA's resource budget.
