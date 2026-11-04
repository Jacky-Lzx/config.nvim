# completion-tools 接入状态

使用本地 dev_plugin_root/completion-tools.nvim；没有未发布仓库的远程 fallback。
启动前需保留该 checkout。LSP 依赖与 capabilities 已切换；Blink 与下列专用扩展未进入当前插件规格。

已接入：LSP、路径（cwd 基准）、同 filetype 缓冲区、LuaSnip、Tab/Enter 接受、
Enter → pairs、Alt-j/k 与 Ctrl-n/p 导航、Alt-u/d 跳五项、文档滚动、
Alt-n/p 按 buffer 循环默认/单词（buffer + dictionary + spell）/snippets/代码来源。LuaSnip 原有 Alt-l/h 跳转与 choice 操作保留。
菜单已恢复 kind 图标｜名称/签名/说明｜kind 名称｜来源的四列布局；名称高亮由 completion-tools 独立实现，
使用 kind 颜色、内置词法规则及可用的原生 Tree-sitter query，缺少解析器时回退；不依赖 colorful-menu。
词典已接入 configs/dictionary.txt，输入至少 3 字符、最多 10 项，后台模糊检索；
拼写已接入原生 spelllang/spellfile，仅在开启 spell 的窗口启用，保留匹配排序及纠错候选。
两者均为 completion-tools 的独立来源，不加载对应 Blink 插件。
Copilot 已由 completion-tools 直接连接官方 Copilot Language Server；不再依赖 copilot.lua。
AI 功能启用时进入默认来源，Alt-i 按 buffer 开关；最多三条紫色候选。
建议复用菜单导航与 Tab/Enter 接受，多行内容保留；请求独立防抖并取消旧结果。
服务端仅在补全请求或显式认证时启动；命令行补全保持冷启动。
使用 :CompletionToolsCopilot auth/status/enable/disable/restart；状态以原来的 Copilot 图标显示在补全窗格底部，等待/生成时有点状旋转动画；状态栏不再显示 Copilot。
运行环境需提供 copilot-language-server（本机已安装），账号凭据由官方服务端管理。
命令行已接入独立补全：: 使用原生命令/参数补全，/ 与 ? 使用缓冲区单词。
input-tools 继续绘制命令行与输入框；候选框通过公开布局 API 避让整个输入窗口。
命令行支持自动显示、方向键/Ctrl-n/p/Alt-j/k、Alt-u/d 跳五项、Tab 接受和 Alt-/ 开关；Enter 保持执行/搜索。
原生 input() 及 Vim 模式输入框仍由 input-tools 管理，后者使用 Ctrl-x Ctrl-u 显式补全。

暂未适配的来源：

- lazydev.integrations.blink：LazyDev 专用模块/路径候选；LazyDev 本身和 LuaLS 类型库仍保留。
- CodeCompanion 的 Blink 来源：聊天 buffer 中专用候选；聊天、请求通知不受影响。
- input-tools.blink / input_tools 来源：输入框自动候选、声明来源自动筛选；
  保留原生 completefunc 的显式补全，Enter 仍先接受候选、再确认输入。

暂未迁移的其他 Blink 功能：

- colorful-menu 针对特定语言服务器的签名改写与特殊格式化；通用语法高亮、kind 图标和列布局已由新插件独立实现。
- ghost text。
- completion.accept.auto_brackets（pairs 普通括号配对继续可用）。
- BibTeX 文档的 Blink draw 回调压缩；通用浮窗压缩 autocmd 仍保留。
- 多行候选强制向上、同一会话固定方向、文档四向优先级与滚动条。
- 原有 LSP → buffer fallback 门控；当前同时请求内置来源，以分数排序。
- Blink 专属 kind/label/sort_text 排序链与持久 frecency；通用来源采用新引擎的 top-k 排序，拼写来源单独提供匹配/原生建议排序。
- LuaSnip 正则 trigger 的菜单预览/占位扩展辅助；LuaSnip 自身的正则/自动 snippet 仍保留。
- 按触发字符启动的补全会话持续隐藏 snippets 的 should_show_items 策略；当前由新引擎按关键字过滤。

原配置 signature.enabled=false，签名帮助原本未启用，不算迁移损失。
没有修改已安装 Blink 目录，也没有执行 Lazy clean；便于后续适配或回退。
