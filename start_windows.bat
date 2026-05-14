@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set "APP_NAME=故事板生成器"
set "PROJECT_DIR=%~dp0"
set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"
set "VENV_DIR=%PROJECT_DIR%\.venv"
set "PORT=18300"

echo === 检查端口 %PORT% ===
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :%PORT%') do (
    if "%%a" NEQ "0" (
        echo   端口 %PORT% 被 PID %%a 占用，正在终止...
        taskkill /F /PID %%a >nul 2>&1
    )
)

if not exist "%VENV_DIR%" (
    echo === 创建 Python 虚拟环境 ===
    python -m venv "%VENV_DIR%"
)

echo === 激活虚拟环境 ===
call "%VENV_DIR%\Scripts\activate.bat"

echo === 检查依赖 ===
python -c "import flask, requests, PIL" >nul 2>&1
if errorlevel 1 (
    echo === 正在安装依赖 ===
    pip install -r "%PROJECT_DIR%\requirements.txt"
)

echo.
echo   ╔══════════════════════════════════════════╗
echo   ║   %APP_NAME% - 开发模式              ║
echo   ╚══════════════════════════════════════════╝
echo.

echo 正在启动后端服务...
start /b python "%PROJECT_DIR%\backend\app.py"

echo.
echo 正在打开前端页面...
start "" "%PROJECT_DIR%\index.html"

echo.
echo 服务已启动！
echo 提示：关闭此窗口并不会停止服务，如需停止请重新运行脚本或手动结束 python 进程。
echo 脚本窗口可以安全关闭。
pause >nul
