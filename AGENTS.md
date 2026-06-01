# AGENTS.md

## Project Overview

Cartoon billiard game built with **Godot 4.7** and **GDScript**. Uses GL Compatibility renderer.

## Directory Structure

- `pool_engine/` - Custom billiard physics engine (pure GDScript, no Godot physics)
  - `billiard_physics.gd` - Core simulation loop, collision detection/response
  - `ball.gd` - Ball state (position, velocity, angular_velocity are Vector3; y = height)
  - `table.gd` - Table boundaries, wall collision detection
  - `physics_constants.gd` - Physical constants (mass, friction coefficients)
  - `demo.gd` - Standalone 2D demo scene
- `.references/foobillardplus/` - Reference implementation from foobillardplus C project
  - `src/billmove.c` - Primary reference for physics algorithms
  - `src/ball.c`, `src/table.c` - Data structures reference

## Physics Engine Notes

**Coordinate system**: Positions/velocities use Vector3 where x/z = table plane, y = height (up). This follows Godot 3D convention.

**Known issue**: Jump ball physics not yet implemented. Currently y-axis movement during collisions is suppressed to prevent balls drifting apart vertically. When implementing jump balls:
- Enable y-axis in collision calculations
- Add gravity in `_proceed_dt()` when `ball.on_table == false`
- Handle landing collision

**Collision detection**: Uses quadratic equation to find exact collision time (`_calc_ball_collision_time`). Returns `t_entry` (negative if balls overlapping, INF if no collision).

## Running the Project

Open in Godot 4.7, run main scene. For physics demo only: run `pool_engine/demo.gd` scene.

## Reference Code

When implementing physics features, consult `.references/foobillardplus/src/billmove.c` for the original C algorithms. Key functions:
- `ball_ball_interaction` - Ball collision response
- `proceed_dt` - Time step integration
- Friction models (slide/roll transitions)
