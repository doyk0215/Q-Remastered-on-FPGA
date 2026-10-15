---
title: "Product Brief: Q Remastered on FPGA"
status: draft
created: 2026-10-14
updated: 2026-10-14
---

# Product Brief: Q Remastered on FPGA

## Executive Summary

Q Remastered on FPGA is a drawing-and-physics puzzle game for the Basys3 development board, inspired by Q REMASTERED. A player draws a limited number of strokes; those strokes become physical objects that can redirect a ball toward a level target. The first version focuses on a small, replayable puzzle loop that can be understood and demonstrated directly on the board.

Gameplay appears on a VGA monitor, while the Pmod OLED presents level selection, objectives, drawing budget, and status. A mouse supplies drawing input; board buttons and switches control the game, and LEDs indicate state. All gameplay is integrated into one bitstream and designed around the FPGA's resource limits.

## The Problem

[ASSUMPTION] The experience this game is designed to improve is the player's ability to influence a puzzle rather than only watch fixed obstacles. Drawing offers a simple way to change the ball's path. The project also explores whether this interaction can remain clear and responsive on a resource-limited FPGA.

## The Solution

The player chooses a level, draws within a limited budget, and releases a stroke to create a movable object. The ball responds to gravity and collisions with drawn objects, fixed obstacles, and level boundaries. The player can pause, retry, and move between levels without reprogramming the board. VGA carries the main playfield; the OLED and board controls provide supporting information and actions.

## What Makes This Different

The project combines mouse-based drawing, a simplified physics puzzle, and an integrated FPGA implementation. The player-created geometry is part of the puzzle solution, and the game presents its controls and status across the Basys3, VGA monitor, and Pmod OLED. The intended distinction is the interactive hardware experience and integration, rather than a claim of novel physics.

## Who This Serves

[ASSUMPTION] The primary user is a player trying a puzzle during a live demonstration; EE2026 assessors are a secondary audience who need to see the system's capabilities quickly. Both need clear controls, visible feedback, and a reliable path from level start to retry or victory.

## Success Criteria

- A player can select or start a level, draw and release an object, and observe the ball respond.
- At least one level can be completed by guiding the ball into a clearly indicated target.
- Pause and retry work without reprogramming the FPGA, and the integrated game remains responsive during a demonstration.
- VGA gameplay, OLED information, and board controls communicate the game state clearly.
- The demonstrated capabilities run together in one bitstream within FPGA resource limits.

These criteria align with the course evaluation areas: functionality, robustness and reliability, user interface, and user experience.

## Scope

The first version includes one ball, a few player-drawn objects, predefined obstacles and targets, a limited drawing budget, and a small set of levels. It uses signed fixed-point physics for gravity, movement, and collisions, with translation and bouncing as the initial motion model. Rotation and large, unbounded object counts are outside the first-version scope. Additional features remain undecided until the core loop fits and works reliably on the board.

## Vision

[ASSUMPTION] If the core loop works well, the game can grow into a compact collection of puzzles that introduce new obstacle layouts or drawing challenges while preserving quick retries and reliable on-board play. Future additions should deepen the same drawing-and-physics experience and remain within the FPGA's resource budget.
