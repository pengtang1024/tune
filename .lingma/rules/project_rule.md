# 核心规范（基于单一职责与flutter_riverpod解耦）

## 一、核心原则
以“单一职责”为基础，结合`flutter_riverpod`的状态管理机制，实现“状态-逻辑-UI”三层解耦，确保每个单元（文件/组件）职责唯一、依赖清晰、可独立维护与复用。


## 二、目录结构与职责划分
### 1. `states` 目录（状态层）
- **状态模型文件**（如`player_state.dart`）
  - 仅定义不可变状态数据结构（`final`字段），包含`copyWith`方法（用于生成新状态）和静态构造函数（如`initial()`）。
  - 纯数据载体，不依赖`riverpod`，不包含任何业务逻辑或方法。

- **状态管理器文件**（如`player_state_notifier.dart`）
  - 继承`StateNotifier`，仅负责状态修改逻辑（如`play()`/`pause()`），通过`riverpod`的`Ref`实现依赖注入（如注入音频服务）。
  - 不直接关联UI，仅通过修改`state`字段更新状态，逻辑封闭在内部。


### 2. `providers` 目录（解耦枢纽）
- **状态提供者文件**（如`player_providers.dart`）
  - 仅定义`StateNotifierProvider`实例（如`final playerProvider = StateNotifierProvider(...)`），作为状态访问的唯一入口。
  - 不包含业务逻辑，仅负责关联状态管理器与状态模型，是UI与状态层解耦的核心：UI通过provider访问状态，无需知晓管理器实现细节。


### 3. `widgets` 目录（UI层）
#### ① 功能组件文件（如`album_cover.dart`、`play_button.dart`）
- 单一职责：仅实现一项项具体UI功能（如展示封面、处理播放按钮点击），包含自身样式与交互逻辑。
- 依赖方式：通过`ConsumerWidget`和`ref.watch(provider)`获取所需状态，通过`ref.read(provider.notifier)`调用状态管理器方法，不直接接依赖状态模型或管理器类。

#### ② 页面组件文件（以`page`结尾，如`player_page.dart`）
- 核心职责：**仅负责组合功能组件，搭建页面整体布局**，无复杂业务代码，主要通过`Column`/`Row`等布局组件拼接功能组件（如`AlbumCover`+`SongInfo`+`PlayerControls`）。
- 辅助职责：处理页面级状态判断（如无数据时显示空状态、加载时显示进度条），不干预子组件的具体功能逻辑。


## 三、flutter_riverpod解耦能力实现
### 1. 状态与UI解耦
- UI组件仅通过provider访问状态（`ref.watch(playerProvider)`）和调用逻辑（`ref.read(playerProvider.notifier).play()`），无需导入状态管理器或模型类。
- 状态修改逻辑封装在管理器中，UI只关注“展示什么”，不关心“如何修改”，更换状态实现时（如换用其他音频库），只需修改管理器和provider，不影响UI。


### 2. 组件间解耦
- 多个组件共享状态时，通过同一provider访问，组件间无直接引用（如`PlayButton`和`ProgressBar`通过`playerProvider`共享播放状态，互不依赖）。
- 新增组件时，只需通过provider获取所需状态，无需修改现有组件，实现“功能扩展不影响旧代码”。


### 3. 依赖注入解耦
- 状态管理器依赖的服务（如音频播放服务、API客户端）通过`Ref`注入（`final audioService = ref.read(audioServiceProvider)`），不硬编码依赖，便于替换（如测试时用模拟服务替代真实服务）。


### 4. 逻辑分层解耦
- 复杂逻辑拆分为多个独立provider组合（如`userInfoProvider`依赖`authProvider`和`profileProvider`），各provider专注单一逻辑，通过`ref.watch`实现按需组合，避免逻辑堆砌。


## 四、功能单一性与解耦协同要求
1. **状态层**：状态模型只存数据，管理器只改状态，两者通过provider暴露，与UI完全隔离。
2. **功能组件**：仅依赖完成自身功能的1-2个provider，不冗余依赖其他状态（如“音量滑块”仅依赖`volumeProvider`，不关心播放状态）。
3. **页面组件**：仅做“布局容器”，通过参数向子组件传递必要配置（如向`AlbumCover`传递`songId`），不传递状态对象，避免组件间状态耦合。
4. **修改边界**：修改任一功能时，仅需改动对应功能组件或状态管理器，页面组件仅在布局调整时修改，不涉及逻辑变更。


通过以上规范，结合`flutter_riverpod`的provider机制，既能保证各单元职责清晰，又能实现多层解耦，大幅提升代码的可维护性、可测试性和扩展性。
在使用Riverpod进行状态管理时，应遵循以下最佳实践：

一、状态更新规范

禁止在Widget生命周期中直接修改Provider状态：
避免在build、initState、dispose、didUpdateWidget、didChangeDependencies等Widget生命周期方法中直接修改Provider状态
这种做法可能导致UI状态不一致，触发异常
推荐的Provider状态更新方式：
(首选) 将状态更新逻辑移出Widget生命周期，例如在按钮的onPressed中执行
使用WidgetsBinding.instance.addPostFrameCallback延迟执行状态更新，确保在当前帧绘制完成后执行
或者使用Future(() {...})将更新操作延迟到下一事件循环执行
路由相关状态更新的处理：
当需要根据路由变化更新状态时，应使用addPostFrameCallback确保更新发生在构建过程之后
示例代码：
WidgetsBinding.instance.addPostFrameCallback((_) {
final currentRoutePath = GoRouterState.of(context).uri.toString();
_updateAppBarState(ref, context, currentRoutePath);
});
二、状态管理原则 4. 状态管理通用原则：

保持状态更新逻辑与UI构建逻辑分离
对于依赖BuildContext的状态更新，确保在上下文有效时执行
避免在状态更新过程中产生循环依赖
三、状态重置与事件设计 5. 状态重置最佳实践：

对于需要重置到初始状态的操作，应设计专门的重置事件（如ResetScanEvent），而不是复用取消事件（CancelScanEvent）
重置事件应确保界面能正确回到初始状态，而不是停留在取消状态
重置操作应保持必要的数据加载功能（如重新加载自定义扫描路径）
事件设计原则：
每个用户操作应有对应且唯一的事件类型
事件命名应清晰表达其用途
避免多个不同操作触发相同事件
新增专门的ResetScanEvent事件来处理重置操作
四、性能优化 7. 状态转换规范：

状态转换应有明确的触发条件和反馈机制
不同操作应有明确的状态反馈
确保应用状态管理的一致性，避免状态混乱的问题
状态转换应确保界面能正确响应，符合用户预期
性能优化措施：
在状态更新前进行值对比，新旧值一致时不通知UI刷新
使用Riverpod精准通知需要更新的UI部分，而不是触发全局刷新
对于频繁变化的状态（如播放状态），应实现防抖机制避免过度刷新

本地化参数的添加，应该根据l10n.yaml获取模板文件，zh_CN.arb为核心模板，根据模板文件添加参数，然后同等更新其他语言文件，最后通过flutter gen-l10n生成各个语言的AppLocalizations
所有修改完成后必须检查是否有编译错误
优先使用流式布局，避免使用网格布局，网格布局在一些场景下会导致布局问题
本地化参数的添加，应该根据l10n.yaml获取模板文件，zh_CN.arb为核心模板，根据模板文件添加参数，然后同等更新其他语言文件，最后通过flutter gen-l10n生成各个语言的AppLocalizations
