# Stage Layouts — Draft

## Decision status

All three stage concepts are user-adopted: Stage 1 push onto a ramp; Stage 2 supported bridge above a barrier; Stage 3 off-centre beam drop for rotation-driven leftward transfer. The coordinates below are engineering seeds for review, not accepted evidence of settling, solvability or final difficulty. The separate development rotation fixture remains a diagnostic baseline.

All three gameplay stages retain one magenta ball, five accepted strokes, at most eight fixed capsules and victory by any ball contact with the full left boundary. Drawn bodies remain dynamic.

## Stage 1 — Push onto a ramp

The user adopted this introductory mechanic: push the initially supported ball left, off its short starting platform, and onto a fixed ramp descending toward the left boundary.

### Proposed initial scene

Use the common 640×480 coordinates, radius-8 fixed capsules, radius-12 ball and zero initial ball velocity/spin.

| Item | Coordinates in pixels |
| --- | --- |
| Ball | Centre (536,156) |
| Starting platform | (520,176) → (592,176) |
| Descending ramp | (488,184) → (16,408) |

There are two fixed capsules. The ball bottom y=168 matches the starting platform top y=168. The ramp descends toward the left, starting below and left of the platform. Rounded-end transfer and contact remain prototype work.

### Candidate player drawing

A first nudge seed is a two-point stroke from (548,80) to (604,112), radius 8, released with zero initial velocity/spin. Its sampled length is sqrt(4160) ≈ 64.5 pixels and its mass is approximately 1.008. It is intended to fall onto the ball's right side and generate leftward motion through contact.

The candidate is not a prescribed solution or an input-throw mechanic. Its impact direction, resulting ball motion and transfer onto the ramp must be established in the implemented physics.

### Intended player sequence and later evidence

1. The ball remains on its starting support until disturbed.
2. An accepted drawing falls, contacts the ball and nudges it left.
3. The ball leaves the starting platform, reaches the ramp and travels toward the left wall.
4. Ball contact with the boundary latches victory before containment correction.

A one-drawing solution is a design target, not an acceptance assumption; a reliable demonstrated solution must use at most the common five-stroke allowance. Record final samples and starting data, check the platform/ramp join and enforce the shared motion budget. Alternative valid routes remain allowed.

## Stage 2 — Bridge above a barrier

The ball starts at rest on a raised platform at the right. A fixed barrier occupies the lower central route. The player releases a beam above two supports, intending it to settle as a crossing above that barrier, then uses another drawing to nudge the ball left onto the bridge and exit ramp.

The first coordinate seed uses a level bridge and a descending fixed exit ramp. It separates the supported crossing from the downhill portion; a sloping bridge remains an alternative if later tuning makes it preferable. Neither a unique route nor an exact two-stroke solution is required.

### Proposed initial scene

All coordinates are pixels in the shared 640×480 space. Static capsules have radius 8; ball radius is 12. The ball starts with zero linear/angular velocity.

| Item | Coordinates |
| --- | --- |
| Ball | Centre (536,204) |
| Starting platform | (520,224) → (592,224) |
| Left bridge support | (224,240) → (248,240) |
| Right bridge support | (464,240) → (488,240) |
| Barrier | (352,280) → (352,471) |
| Exit ramp | (192,224) → (16,400) |

There are five fixed capsules. The ball's bottom y=216 matches the starting platform's top y=216. These are initial design calculations, not an executed stability check.

### Candidate first drawing

- Release a two-point beam from (208,144) to (504,144), radius 8.
- Total sampled length is 296 pixels, above the 16-pixel minimum; mass is 296/64=4.625.
- Its centre of mass is (356,144), horizontally between the proposed supports.
- The intended resting centerline is (208,224) → (504,224), after an 80-pixel fall.
- At that target, the beam's bottom y=232 meets the supports' top y=232. Its underside is 40 pixels above the barrier's top y=272.
- The right starting platform and left exit ramp meet the candidate bridge near rounded capsule ends. Ball transfer across those joins, beam settling/tilting/sliding and all other contacts require validation.

The intended resting pose is not an attachment, teleport or solver result. The beam may translate or rotate under ordinary contact response. The level must not freeze it or introduce a hinge.

### Intended player sequence

1. Place the bridge above the supports without initial overlap.
2. Let it fall and settle through the regular physics update.
3. Release a further object to push the ball left.
4. Guide the ball across the supported beam, onto the left-descending fixed ramp, and into the left boundary.

Two accepted drawings would leave three allowance; that is an illustrative plan, not a proven stroke count or recorded solution. Alternative valid solutions are allowed.

### Evidence required later

- The undisturbed ball remains on its starting support and does not auto-complete.
- The bridge is admissible, settles usefully and remains a dynamic rigid body.
- The ball crosses the rounded joins and passes above the barrier without penetration, falling through or a hidden constraint.
- A recorded player drawing sequence reaches the left boundary using at most five accepted strokes.
- Record the final sampled points, complete initial scene and parameter/profile revisions for reproduction.
- Use the adopted gravity/contact/mass/motion limits; revise this draft if the intended crossing or nudge is unreliable.

## Stage 3 — Off-centre beam drop

The user adopted stroke rotation as the final puzzle's intended mechanic. A horizontal player beam falls onto a pedestal to the right of its centre of mass. The off-centre contact should lower its left end into the ball, transferring momentum left toward the exit ramp and goal.

### Proposed initial scene

Use the common 640×480 coordinates, radius-8 fixed capsules, radius-12 ball and zero initial ball velocity/spin.

| Item | Coordinates in pixels |
| --- | --- |
| Ball | Centre (368,352) |
| Off-centre pedestal | (464,320) → (496,320) |
| Ball support | (320,372) → (384,372) |
| Exit ramp | (304,380) → (16,448) |

There are three fixed capsules. The ball bottom y=364 matches its support top y=364. The ramp begins below and left of the ball support; rounded-end transfer remains to be demonstrated.

### Candidate player drawing

- Release a two-point beam from (368,240) to (528,240), radius 8, with zero initial velocity/spin.
- Sampled length is 160 pixels; mass is 2.5 and centre of mass is (448,240).
- The pedestal's horizontal contact span x=464..496 is entirely to the right of that mass centre.
- A horizontal beam reaches first pedestal contact at centerline y=304, after a 64-pixel fall. The ball remains clear of the beam at that first contact.
- Intended contact response tips the left end downward toward the ball. The support remains an ordinary collision body; there is no hinge, fixed pivot, attachment or preset angular impulse.

The illustration's 25-degree pose and ball displacement were hand-selected explanatory states. They are not required trajectories, simulation output or measured solver behavior. Actual sliding, contact changes, rotation and impact must emerge from the implemented physics.

### Intended player sequence and later evidence

1. Admit the non-overlapping beam and let gravity bring it onto the pedestal.
2. Record contact-driven angular velocity and visible left-end-down rotation.
3. Demonstrate actual beam/ball contact and resulting leftward ball movement.
4. Guide the ball off its support, onto the exit ramp and into the left boundary within five accepted drawings.

A one-beam solution is a design target, not a proven stroke count. Additional accepted drawings and alternative valid solutions are allowed. Revise initial coordinates or permitted tuning if the intended transfer/ramp route is unreliable, and record a reproducible solution using the actual final samples.

This stage adapts the separate development fixture toward the left goal. It does not replace rotation-fixture.md's right-end-down baseline; that baseline isolates rotation evidence and is not itself a proven gameplay solution.

No tests, physics simulation, synthesis or board execution were performed when specifying this draft.
