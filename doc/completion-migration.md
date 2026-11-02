# completion-tools 接入状态

使用本地 dev_plugin_root/completion-tools.nvim；没有未发布仓库的远程 fallback。
启动前需保留该 checkout。LSP 依赖与 capabilities 已切换；Blink 与下列专用扩展未进入当前插件规格。

已接入：LSP、路径（cwd 基准）、同 filetype 缓冲区、LuaSnip、Tab/Enter 接受、
Enter → pairs、Alt-j/k 与 Ctrl-n/p 导航、Alt-u/d 跳五项、文档滚动、
Alt-n/p 按 buffer 循环默认/单词/snippets/代码来源。LuaSnip 原有 Alt-l/h 跳转与 choice 操作保留。
input-tools 仍显示命令行/输入框及原生 popupmenu；Ex 用 Tab，输入框用 Ctrl-x Ctrl-u 显式补全。

暂未适配的来源：

- blink-copilot：Copilot 菜单建议及 Alt-i 来源开关；独立 Copilot 命令/状态保留。
- blink-cmp-dictionary：自定义词典候选。
- blink-cmp-spell：拼写候选及其排序。
- lazydev.integrations.blink：LazyDev 专用模块/路径候选；LazyDev 本身和 LuaLS 类型库仍保留。
- CodeCompanion 的 Blink 来源：聊天 buffer 中专用候选；聊天、请求通知不受影响。
- input-tools.blink / input_tools 来源：输入框自动候选、声明来源自动筛选；
  保留原生 completefunc 的显式补全，Enter 仍先接受候选、再确认输入。
  Ex 命令行由自动菜单改为原生 Tab 触发；外置 UI 继续归 input-tools。
  原命令行 Alt-j/k、Alt-u/d、Alt-/ 补全专属快捷键暂未迁移。

暂未迁移的其他 Blink 功能：

- colorful-menu 的 Treesitter 菜单高亮、kind 图标/列布局；目前使用内置 label + 来源布局。
- ghost text。
- completion.accept.auto_brackets（pairs 普通括号配对继续可用）。
- BibTeX 文档的 Blink draw 回调压缩；通用浮窗压缩 autocmd 仍保留。
- 多行候选强制向上、同一会话固定方向、文档四向优先级与滚动条。
- 原有 LSP → buffer fallback 门控；当前同时请求内置来源，以分数排序。
- Blink 专属 kind/label/sort_text 排序链、拼写纠错与持久 frecency；采用新引擎的 top-k 排序。
- LuaSnip 正则 trigger 的菜单预览/占位扩展辅助；LuaSnip 自身的正则/自动 snippet 仍保留。
- 按 LSP 触发会话持续隐藏 snippets 的 should_show_items 策略；当前由新引擎按关键字过滤。

原配置 signature.enabled=false，签名帮助原本未启用，不算迁移损失。
没有修改已安装 Blink 目录，也没有执行 Lazy clean；便于后续适配或回退。
