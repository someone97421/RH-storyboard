# RunningHubAI Storyboard Generator / RunningHubAI 故事板生成器

## 中文使用方式

这是一个本地运行的 RunningHubAI 故事板生成工具。前端页面用于编辑提示词、提交任务、轮询任务状态并查看结果；Python 后端作为本地代理，负责解决浏览器跨域请求问题。

### 环境要求

- Python 3.10+
- RunningHub API Key
- 可选：LLM API Key，用于生成或优化提示词

### 本地运行

```bash
python -m venv .venv
.venv\Scripts\activate
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
python backend/app.py
```

启动后浏览器会自动打开本地页面；也可以手动访问终端中显示的 `http://127.0.0.1:<端口>`。

### 基础使用

1. 在设置中填写 RunningHub Base URL 和 API Key。
2. 按需填写 LLM Base URL、API Key 和模型名称。
3. 在主界面输入故事板或视频提示词。
4. 上传参考图或使用纯文本生成。
5. 点击生成按钮后，在右侧任务列表查看排队、提交、轮询和完成状态。
6. 展开任务调试信息可以查看任务 ID、轮询次数、参数和错误信息。

### macOS 打包

```bash
bash build_mac.sh
```

打包产物会输出到 `dist/`。更多说明见 `MAC_BUILD_README.md`。

### 本地文件说明

`.venv/`、`build/`、`dist/`、`.DS_Store`、`*.spec`、安装包和日志文件都已在 `.gitignore` 中隔离，不会作为核心代码提交。

## English Usage

This is a local RunningHubAI storyboard generation tool. The frontend lets you edit prompts, submit jobs, poll task status, and inspect results. The Python backend works as a local proxy to avoid browser CORS issues.

### Requirements

- Python 3.10+
- RunningHub API Key
- Optional: LLM API Key for prompt generation or refinement

### Run Locally

```bash
python -m venv .venv
.venv\Scripts\activate
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
python backend/app.py
```

After startup, the browser should open automatically. You can also visit the `http://127.0.0.1:<port>` URL shown in the terminal.

### Basic Workflow

1. Enter your RunningHub Base URL and API Key in settings.
2. Optionally enter your LLM Base URL, API Key, and model name.
3. Write a storyboard or video prompt on the main page.
4. Upload reference images or generate from text only.
5. Click the generate button, then watch queue, submit, polling, and completion status in the task sidebar.
6. Expand task debug details to inspect task IDs, poll attempts, parameters, and errors.

### macOS Build

```bash
bash build_mac.sh
```

Build outputs are written to `dist/`. See `MAC_BUILD_README.md` for more details.

### Local Files

`.venv/`, `build/`, `dist/`, `.DS_Store`, `*.spec`, installer packages, and logs are excluded by `.gitignore` so local cache and build artifacts stay out of source control.
