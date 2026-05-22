## 智能体技能 (Agent skills)

**【全局指令】**：在处理此代码库的所有任务时，智能体**必须**使用中文进行内部思考、对话和交流。

### 问题追踪器 (Issue tracker)

本项目使用 GitHub Issues 进行任务追踪，通过 `gh` CLI 交互。详见 `docs/agents/issue-tracker.md`。

### 任务分类标签 (Triage labels)

使用标准的 5 种默认角色标签进行任务分类。详见 `docs/agents/triage-labels.md`。

### 领域知识文档 (Domain docs)

本项目为单上下文（Single-context）代码库，使用根目录的 `CONTEXT.md` 和 `docs/adr/` 目录。详见 `docs/agents/domain.md`。