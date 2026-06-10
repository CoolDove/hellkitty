# AGENTS.md

## Project Overview

Cartoon billiard game built with **Godot 4.7** and **GDScript**. Uses GL Compatibility renderer.

## Directory Structure

- `pool_engine/` - Custom billiard physics engine (pure GDScript, no Godot physics)
  - `billiard_physics.gd` - Core simulation loop, collision detection/response
  - `billiard_collision_2d.gd` - ✨ NEW: Unified collision node system (RECT + CIRCLE shapes)
  - `billiard_scene_manager.gd` - ✨ NEW: Scene management with collision visualization
  - `ball.gd` - Ball state (position, velocity, angular_velocity are Vector3; y = height)
  - `table.gd` - Table boundaries, wall collision detection (legacy, now optional)
  - `physics_constants.gd` - Physical constants (mass, friction coefficients)
  - `demo.gd` - Scene controller with physics simulation
- `.references/foobillardplus/` - Reference implementation from foobillardplus C project
  - `src/billmove.c` - Primary reference for physics algorithms
  - `src/ball.c`, `src/table.c` - Data structures reference

- `tscns/billiard.tscn` - Main playable scene with collision testing

## Physics Engine Notes

**Coordinate system**: Positions/velocities use Vector3 where x/z = table plane, y = height (up). This follows Godot 3D convention.

**Known issue**: Jump ball physics not yet implemented. Currently y-axis movement during collisions is suppressed to prevent balls drifting apart vertically. When implementing jump balls:
- Enable y-axis in collision calculations
- Add gravity in `_proceed_dt()` when `ball.on_table == false`
- Handle landing collision

**Collision detection**: Uses quadratic equation to find exact collision time (`_calc_ball_collision_time`). Returns `t_entry` (negative if balls overlapping, INF if no collision).

## Running the Project

Open in Godot 4.7, run main scene. For physics demo only: run `pool_engine/demo.gd` scene.

## Agent 工作规范
当你需要更新文档时，尽量都写在这个AGENTS.md中，除非我要求，否则不要新开乱七八糟的新md文件。简要地写下你的设计，不要用太长的篇幅做过多的介绍。

## Reference Code

When implementing physics features, consult `.references/foobillardplus/src/billmove.c` for the original C algorithms. Key functions:
- `ball_ball_interaction` - Ball collision response
- `proceed_dt` - Time step integration
- Friction models (slide/roll transitions)

## Godot 4.7 知识点
### gdscript语法
```
var foo := bar()
```
这种语法需要能够正确地判断foo的类型才能使用。鉴于你不具备判断是否能用这个语法的情况，所以请尽量都使用`var foo = bar()`这样的动态类型形式。

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

## BilliardCollision2D 碰撞系统

统一的碰撞节点系统，单一类支持多种形状。

### 形状类型
- `RECT` - 矩形（墙壁）：需配置 position_2d, rect_half_x, rect_half_z, rect_normal
- `CIRCLE` - 圆形（口袋/障碍物）：需配置 position_2d, circle_radius, circle_mode
  - `OUTLINE` 模式：球反弹（障碍物）
  - `SINK` 模式：球被吸收（口袋）

### 快速示例
```gdscript
# 创建左墙
var wall = BilliardCollision2D.new()
wall.shape_type = BilliardCollision2D.ShapeType.RECT
wall.position_2d = Vector2(-1.27, 0)
wall.rect_half_x = 0.05
wall.rect_half_z = 0.635
wall.rect_normal = Vector3(1, 0, 0)  # 法线指向台面内部
add_child(wall)
physics.add_collision_node(wall)
```

### BilliardSceneManager (继承 Node3D)
自动创建4面墙，管理碰撞节点，提供可视化。
- `add_pocket(Vector2, radius)` - 添加口袋
- `add_obstacle(Vector2, radius)` - 添加障碍物
- `toggle_debug_visualization()` - 切换可视化（橙色=墙，红色=口袋，绿色=障碍物）

### billiard.tscn 测试场景控制
- 左键：射击台球
- R：重置场景
- D：切换碰撞可视化
- C：打印碰撞信息

