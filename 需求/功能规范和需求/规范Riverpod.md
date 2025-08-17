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
