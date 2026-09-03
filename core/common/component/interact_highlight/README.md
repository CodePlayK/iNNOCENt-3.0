# InteractHighlight — 可交互物品光点 → 轮廓粒子效果

专为 Godot 4.x（含 4.7）2D 项目设计。

## 功能概览

- **不覆盖原 Sprite 的 material**（高亮画在独立 OutlineOverlay 上）
- **支持多种动画形式**
  - `Sprite2D`（含 region / hframes / vframes）
  - `AnimatedSprite2D`
  - `Sprite2D + AnimationPlayer`（自动监听动画切换，每帧同步轮廓）
- **可导出触发 Area2D**
  - 通过 `interaction_type` 选择触发方式：
	- `BODY`：body_entered / body_exited（角色碰撞）
	- `MOUSE`：mouse_entered / mouse_exited（鼠标悬停）
	- `BOTH`：两种都监听（带引用计数，避免冲突）
  - 未指定 Area2D 时自动创建，并可生成近似 CollisionShape2D

## 效果

- 空闲：中心缓慢闪烁光点
- 交互：粒子向外飞过头 → 回弹附着在**当前帧**轮廓，同时出现高亮 outline
- 结束：粒子从轮廓飞回中心汇聚，光点恢复

## 快速使用

1. 把 `interact_highlight` 文件夹放到项目（如 `res://interact_highlight/`）
2. 在物品节点下添加 `Node2D`，挂 `InteractHighlight.gd`
3. 设置：
   - `Target Sprite` → 你的 Sprite2D / AnimatedSprite2D
   - （可选）`Animation Player` → 驱动该 Sprite 的 AnimationPlayer
   - `Trigger Area` → 已有 Area2D，或留空自动创建
   - `Interaction Type` → Body / Mouse / Both
4. 运行后进入范围/鼠标悬停会自动触发效果；也可手动调用：

```gdscript
$InteractHighlight.play_spread()
$InteractHighlight.play_converge()
$InteractHighlight.set_interacting(true/false)
```

## 推荐节点结构

```
InteractableItem
├── Sprite2D                 ← material 保持原样
├── AnimationPlayer          ← 可选，驱动 frame / region 等
└── InteractHighlight        ← 本脚本（position 建议为 0）
	├── OutlineOverlay       （自动）
	├── InteractTrigger      （自动创建的 Area2D，或你指定的）
	│   └── CollisionShape2D
	├── 粒子...
	└── 空闲光点
```

## Inspector 主要参数

| 分组 | 参数 | 说明 |
|------|------|------|
| Target | Target Sprite | Sprite2D 或 AnimatedSprite2D |
| Target | Animation Player | Sprite2D+AnimationPlayer 时指定 |
| Trigger | Trigger Area | 触发 Area2D，空则自动创建 |
| Trigger | Interaction Type | Body / Mouse / Both |
| Trigger | Auto Create Collision | 自动创建时是否生成矩形碰撞 |
| Particles | Particle Count / Color / Size | 粒子外观 |
| Particles | Overshoot | 飞过头程度（建议 1.25~1.5） |
| Particles | Auto Sync Every Frame | 动画时建议开启 |

## 手动刷新轮廓

换 texture 或 AnimationPlayer 切帧后若需要立刻更新：

```gdscript
$InteractHighlight.refresh_outline()
```

## 运行时切换触发方式

```gdscript
$InteractHighlight.set_interaction_type(InteractHighlight.InteractionType.MOUSE)
```

## 文件

- `InteractHighlight.gd`
- `outline_spread.gdshader`
- `README.md`
