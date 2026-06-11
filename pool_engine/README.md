# Billiard Physics Engine for Godot 4.x

基于 foobillardplus 的台球物理引擎 GDScript 实现。

## 文件结构

```
godot/
├── physics_constants.gd  # 物理常量（质量、摩擦系数等）
├── ball.gd              # 球类（状态、属性）
├── table.gd             # 球桌类（边界、墙壁碰撞）
├── billiard_physics.gd  # 核心物理引擎
├── demo.gd              # 演示场景脚本
└── README.md
```

## 使用方法

### 1. 基本设置

```gdscript
# 创建球桌和物理引擎
var table := Table.new(2.54, 1.27)  # 宽度, 高度 (米)
var physics := BilliardPhysics.new(table)

# 添加球
var cue_ball := Ball.new(0, Vector2(-0.6, 0))
physics.add_ball(cue_ball)

var ball1 := Ball.new(1, Vector2(0.5, 0))
physics.add_ball(ball1)
```

### 2. 运行物理模拟

```gdscript
func _process(delta: float) -> void:
    physics.step(delta)
    
    if not physics.is_simulation_active():
        # 所有球已停止
        pass
```

### 3. 击球

```gdscript
# 直接设置母球速度
cue_ball.velocity = Vector3(3.0, 0, 0.5)  # 向右前方击球 (x,z=桌面, y=高度)

# 或使用冲量
cue_ball.apply_impulse(Vector3(0.5, 0, 0))
```

## 物理特性

### 已实现
- ✅ 球-球弹性碰撞
- ✅ 球-墙碰撞（带能量损失）
- ✅ 滑动摩擦（球面相对桌面滑动）
- ✅ 滚动摩擦（纯滚动阻力）
- ✅ 球间摩擦（角动量传递）
- ✅ 旋转/塞球效果

### 待实现（跳球支持已预留）
- ⬜ 跳球物理（`ball.on_table = false` 时的空中运动）
- ⬜ 重力影响
- ⬜ 空气阻力

## 物理常量

| 常量 | 值 | 说明 |
|------|-----|------|
| BALL_MASS | 0.17 kg | 球质量 |
| BALL_DIAMETER | 57.15 mm | 球直径 |
| MU_ROLL | 0.03 | 滚动摩擦系数 |
| MU_SLIDE | 0.2 | 滑动摩擦系数 |
| MU_BALL | 0.1 | 球间摩擦系数 |
| CUSHION_LOSS0 | 0.2 | 边框基础能量损失 |

## 运行演示

1. 创建新的 Godot 4.x 项目
2. 将所有 `.gd` 文件复制到项目中
3. 创建新场景，添加 Node2D 节点
4. 将 `demo.gd` 附加到该节点
5. 运行场景
6. 点击鼠标左键击球，按 R 重置

## 扩展跳球

当需要实现跳球时，修改以下部分：

```gdscript
# 在 billiard_physics.gd 的 _proceed_dt() 中
if ball.on_table:
    _apply_table_friction(ball, dt)
else:
    # 空中物理 (y = height in Godot convention)
    ball.velocity.y -= PhysicsConstants.GRAVITY * dt
    # 检测落地
    if ball.position.y <= 0:
        ball.position.y = 0
        ball.on_table = true
        # 处理落地碰撞...
```
