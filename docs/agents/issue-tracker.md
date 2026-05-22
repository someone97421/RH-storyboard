# 问题追踪器 (Issue tracker)

本代码库使用 GitHub Issues 追踪问题与任务。

**【全局指令】**：在处理此代码库的所有任务时，智能体**必须**使用中文进行内部思考、对话和交流。

智能体**必须**使用 `gh` 命令行工具来处理 issues：
- 创建 Issue: `gh issue create --title "..." --body-file ...`
- 列表查看: `gh issue list`
- 查看详情: `gh issue view <number>`
- 添加评论: `gh issue comment <number> --body "..."`
- 编辑标签: `gh issue edit <number> --add-label "..."`
