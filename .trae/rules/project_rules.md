AI相关：优先使用mcp的插件将复杂问题分解为步骤
日志使用Log类
日志级别：info、warn、error
日志格式：[时间] [级别] [消息]
日志级别：
info：普通信息，用于记录应用运行状态
warn：警告信息，用于记录潜在问题
error：错误信息，用于记录运行时错误
本地化参数的添加，应该根据l10n.yaml获取模板文件，zh_CN.arb为核心模板，根据模板文件添加参数，然后同等更新其他语言文件，最后通过flutter gen-l10n生成各个语言的AppLocalizations类
启动默认使用flutter run -d windows
优先使用flutter analyze命令检查代码，修复代码中的问题
使用flutter test命令运行测试
文件尽量不要超过200行，超过200行的文件应该考虑拆分
ui层代码应该放到lib/ui目录下
所有widget都应该尽量的小
状态管理：使用flutter_riverpod管理状态
路由管理：使用go_router管理路由
网络请求：使用dio管理网络请求
主题：使用flex_color_scheme
颜色都应该和主题相关
尽量不使用硬编码,所有的字符串,数字等都应该有专门的constants类来管理
所有的widget都应该有对应的测试文件
代码要尽量的简短，每个函数的行数不要超过50行
重复代码应该被提取到单独的函数或类中，避免重复编写相同的代码