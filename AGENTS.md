# Tune 工程规范

## 最高优先级：架构优化优先于代码优化

任何改动都必须先检查架构，再检查代码细节。架构优化不是「有空再做」的附加项，而是所有实现工作的前置条件。

### 必须遵守的顺序

1. **边界**：谁拥有状态？谁负责持久化？谁负责 UI 编排？
2. **依赖方向**：UI → controller → service → data，禁止反向依赖和跨 feature 的 UI 依赖。
3. **单一事实来源**：同一份数据只能有一个权威状态源。
4. **生命周期**：provider 不持有 `BuildContext`；不在 build 中写 provider；不用 post-frame 补状态。
5. **接口**：先定义稳定的 service/controller 接口，再写实现。
6. **代码细节**：命名、拆分、`const`、缓存、`RepaintBoundary` 等性能优化放在最后。

### 明确禁止

- 用 `Future.delayed`、`addPostFrameCallback`、`setState` 掩盖状态同步问题。
- 同一个业务状态在两个 provider 或两个 service 中各存一份。
- `data/`、`domain/` 反向依赖 `features/` 或 `ui/`。
- `features/library` 依赖 `features/player` 的 UI；`features/player` 依赖 `features/library` 的 UI。
- 为了兼容错误结构而不断增加判空、兼容分支和重复同步代码。
- 在没有定义清楚状态归属前，先做局部性能优化。

### 改动前自检

- 这次改动是否让职责更单一？
- 是否减少了跨层依赖或重复状态？
- 新增一个页面/平台时，是否只需接一个新入口，而不是修改一圈旧代码？

三个问题中有两个以上回答「否」，应先调整方案，而不是继续写代码。

## 当前迁移约定

- 新 UI 位于 `lib/app` 与 `lib/features`。
- 旧 `lib/ui` 在迁移期保留，新链路验收后再清理。
- 播放状态唯一来源：`PlaybackController`。
- 队列是 `PlaybackState` 的一部分，不再使用 `PlaylistService` 的私有可变列表。
- 现有未提交修改不回退、不覆盖；清理旧代码前先确认引用关系。
