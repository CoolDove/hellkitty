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

## Godot 4.7 知识点

### 旋转和三维变换

**轴角旋转（Axis-Angle Rotation）**：
- ❌ `Basis.from_axis_angle()` 在Godot 4.7中不存在
- ✅ 使用 `Quaternion(axis, angle)` 创建轴角四元数，然后转换为Basis：
  ```gdscript
  var axis = Vector3(0, 1, 0)  # 旋转轴
  var angle = PI / 4           # 弧度
  var quaternion = Quaternion(axis, angle)
  var basis = Basis(quaternion)
  ```

**增量旋转应用**：
- 要应用增量旋转到现有的Basis，需要相乘：
  ```gdscript
  rotation = delta_rotation * rotation  # 先应用增量，再乘以现有旋转
  ```

**位置与旋转同步**：
- `global_position` - 全局位置
- `global_transform.basis` - 全局旋转矩阵
- `global_transform` - 完整的位置+旋转+缩放

### 坐标系约定

在ball.gd中：
- X, Z轴 = 台面平面
- Y轴 = 高度（向上）
- 这遵循Godot 3D的右手坐标系
