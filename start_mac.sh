#!/bin/bash
# macOS 开发调试启动脚本 —— RunningHubAI 故事板生成器
# Usage: ./start_mac.sh

set -e

APP_NAME="故事板生成器"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
VENV_DIR="$PROJECT_DIR/.venv"
PORT=18300

# ── 强占端口：检查并杀死占用 18300 的进程 ──────────────
echo "=== 检查端口 $PORT ==="
PID=$(lsof -ti tcp:$PORT 2>/dev/null || true)
if [ -n "$PID" ]; then
    echo "  端口 $PORT 被 PID $PID 占用，正在终止..."
    kill -9 "$PID" 2>/dev/null && echo "  已强制终止 PID $PID" || echo "  终止失败，尝试继续..."
    sleep 0.5
fi

# ── 检查 venv ───────────────────────────────────────────
if [ ! -d "$VENV_DIR" ]; then
    echo "=== 创建 Python 虚拟环境 ==="
    python3 -m venv "$VENV_DIR"
fi

source "$VENV_DIR/bin/activate"

# ── 检查依赖 ────────────────────────────────────────────
if ! python -c "import flask, requests, pillow" 2>/dev/null; then
    echo "=== 安装依赖 ==="
    pip install -r "$PROJECT_DIR/requirements.txt"
fi

# ── 启动服务 ────────────────────────────────────────────
echo ""
echo "  ╔══════════════════════════════════════════╗"
echo "  ║   $APP_NAME - 开发模式              ║"
echo "  ╚══════════════════════════════════════════╝"
echo ""
python "$PROJECT_DIR/backend/app.py"
