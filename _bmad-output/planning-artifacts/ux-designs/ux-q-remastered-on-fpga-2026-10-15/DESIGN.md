---
name: Q Remastered on FPGA
description: Visual system for the mouse-driven Basys3 drawing-and-physics puzzle.
colors:
  background: "#000000"
  foreground: "#FFFFFF"
  accent: "#FF00FF"
typography:
  headings: pixel-style bitmap
  body: plain readable bitmap
rounded: {}
spacing: {}
components: {}
---

# Q Remastered on FPGA — Design Spine

> Draft. The user selected the visual direction, palette, typography, and first-pass screen layout. Shape details, component geometry, and hit regions still need to be checked against the VGA and OLED display limits.

## Brand & Style

Use a restrained retro arcade direction: crisp geometric forms, compact labels, and a small high-contrast palette. The fixed platform context is a VGA gameplay screen, a Pmod OLED for supporting stage/status information, and LEDs for status. Styling must keep the game objects and mouse affordances distinct at the actual display resolution.

## Colors

Use a three-color palette that fits the restrained retro arcade direction and the Basys3 display outputs:

| Token | Value | Role |
|---|---|---|
| Background | `#000000` | VGA playfield and OLED background |
| Foreground | `#FFFFFF` | User-drawn strokes, main text, fixed geometry, and high-contrast outlines |
| Accent | `#FF00FF` | Moving ball, left goal boundary, active controls, cursor emphasis, and brief feedback |

Keep the left goal boundary, ball, cursor, and drawn strokes distinguishable by shape, outline, or marking as well as color. Do not rely on color alone for an object role or game state.

Mark the full left display edge as the goal using magenta plus an outline, pattern, or directional cue. Its visual marking must correspond to the display edge; decorative thickness does not move the win boundary into the playfield. The OLED objective should say “Touch the left edge.”

## Typography

Use pixel-style bitmap text for headings and plain, readable bitmap text for body labels and instructions. Keep wording short and use a small number of text sizes. Set exact glyph sizes after the VGA mode and OLED layout are confirmed; those display details are not established in the UX sources.

## Layout & Spacing

- **Lobby:** Use the full VGA view for clickable stage choices.
- **Gameplay:** Use the full VGA view as the playfield, with the two-bar pause control at the upper-left. Keep a persistent status strip off the VGA playfield.
- **Pause availability:** Disable pause while the left mouse button is held. Show its unavailable/pressed state clearly; a drawing release over the icon does not activate it. Activation requires a separate UI click after the draw is released.
- **Pause and victory:** Show each menu as an overlay on the VGA view. Pause offers Resume, Reset Stage, and Back to Lobby. Victory offers Next Stage when available and Back to Lobby; the final stage offers Back to Lobby.
- **Pause-menu backdrop:** Clicking outside the menu items keeps the overlay open and the game paused. Do not make the backdrop a resume control or drawing surface.
- **OLED:** Show the current stage, objective, strokes remaining, and game status.

Exact pixel geometry, hit-region sizes, and OLED text arrangement depend on the confirmed display modes and mouse mapping.

Show rejected-stroke feedback briefly on VGA using the existing readable bitmap text and feedback styling: “Stroke overlaps an object.” Clear the invalid preview and leave the OLED stroke count unchanged.

## Elevation & Depth

[OPEN] Decide whether depth, layering, outlines, or shadows are needed once render constraints are known. The VGA screen must keep overlapping physics objects legible.

## Shapes

Use the supplied [object proportion reference](imports/object-scale-reference.png): the magenta circle is the moving ball, and the white curve is a user-drawn object. At 640×480, the initial ball diameter is 24 pixels (radius 12) and stroke thickness is 16 pixels (capsule radius 8). These are uniformly scaled, rounded prototype defaults; the reference's interior is about 1,334 pixels wide, its ball about 50 pixels across and its central stroke about 35 pixels thick. Physics, preview and display share the same radii.

[OPEN] Define remaining corner, line, fixed-obstacle, and icon geometry within the selected retro arcade direction. The pause control remains a two-bar icon at the upper-left; the screenshot's other UI does not replace the adopted interactions. Wall decoration thickness does not change the physical goal at x=0.

## Components

The first-pass layout and palette are set; exact component geometry and hit regions remain for the display and mouse decisions in architecture. The component inventory must match `EXPERIENCE.md`: Stage card, Gameplay playfield, Mouse cursor, Pause control, Pause menu, Drawn stroke, Ball, Fixed obstacle, Goal boundary, OLED status, Status LEDs, and Victory state.

## Do's and Don'ts

- Do preserve clear visual separation among the cursor, ball, left goal boundary, obstacles, strokes, and other container boundaries.
- Do show the stage objective and remaining stroke count in the supporting OLED role defined by the PRD.
- Do keep gameplay input mouse-only.
- Don't infer a palette from the Q REMASTERED inspiration alone.
- Don't rely on color alone to communicate object type or game state.
