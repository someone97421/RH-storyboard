"""
RunningHubAI 故事板生成器 - Python Backend Proxy
Serves the frontend and proxies all external API calls to avoid CORS issues.
"""

import os
import sys
import json
import time
import socket
import webbrowser
import threading
import requests
from flask import Flask, request, Response, send_from_directory, jsonify, stream_with_context

# Resolve paths for both dev and PyInstaller frozen bundle
if getattr(sys, 'frozen', False):
    BASE_DIR = os.path.dirname(sys.executable)
    FRONTEND_DIR = os.path.join(sys._MEIPASS, 'frontend')
else:
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))
    FRONTEND_DIR = os.path.join(os.path.dirname(BASE_DIR))

app = Flask(__name__)

@app.before_request
def log_request():
    """Log each incoming request to stdout."""
    ts = time.strftime('%H:%M:%S')
    print(f"  [{ts}] {request.method} {request.path}")

@app.after_request
def add_cors_headers(response):
    """Allow local frontend variants to reach the proxy during development."""
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Headers'] = (
        'Content-Type, Authorization, X-LLM-Base-URL, X-RunningHub-Base-URL'
    )
    response.headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
    return response

# ── Frontend Serving ─────────────────────────────────────────────

@app.route('/')
def index():
    return send_from_directory(FRONTEND_DIR, 'index.html')

@app.route('/favicon.png')
def favicon():
    return send_from_directory(FRONTEND_DIR, 'favicon.png')


@app.route('/api/health')
def health():
    return jsonify({'ok': True, 'service': 'runninghubai-proxy'})


# ── Image Proxy ──────────────────────────────────────────────────

@app.route('/api/proxy-image')
def proxy_image():
    """Fetch an external image server-side to bypass browser CORS."""
    url = request.args.get('url', '')
    if not url:
        return jsonify({'error': 'Missing url parameter'}), 400

    try:
        resp = requests.get(url, timeout=30, stream=True)
        excluded = {'content-encoding', 'content-length', 'transfer-encoding', 'connection'}
        headers = {k: v for k, v in resp.raw.headers.items() if k.lower() not in excluded}
        return Response(resp.content, status=resp.status_code, headers=headers)
    except Exception as e:
        return jsonify({'error': str(e)}), 502


# ── RunningHub API Proxy ─────────────────────────────────────────

@app.route('/api/runninghub/<path:subpath>', methods=['POST', 'OPTIONS'])
def proxy_runninghub(subpath):
    """
    Generic proxy for all RunningHub API endpoints.
    Frontend calls: POST /api/runninghub/openapi/v2/...
    Backend forwards to: https://www.runninghub.cn/openapi/v2/...
    """
    if request.method == 'OPTIONS':
        return Response(status=204)

    # The user's configured RunningHub base URL is sent as a header
    base_url = request.headers.get('X-RunningHub-Base-URL', 'https://www.runninghub.cn').rstrip('/')
    auth = request.headers.get('Authorization', '')

    target_url = f"{base_url}/{subpath}"

    headers = {
        'Content-Type': 'application/json',
        'Authorization': auth,
    }

    try:
        body = request.get_data()
        resp = requests.post(target_url, data=body, headers=headers, timeout=120)

        excluded = {'content-encoding', 'content-length', 'transfer-encoding', 'connection'}
        resp_headers = {k: v for k, v in resp.headers.items() if k.lower() not in excluded}

        return Response(resp.content, status=resp.status_code, headers=resp_headers)
    except requests.exceptions.Timeout:
        return jsonify({'error': 'RunningHub API 请求超时'}), 504
    except Exception as e:
        return jsonify({'error': str(e)}), 502


# ── LLM API Proxy (Streaming SSE) ───────────────────────────────

@app.route('/api/llm/chat/completions', methods=['POST', 'OPTIONS'])
def proxy_llm():
    """
    Streaming proxy for OpenAI-compatible LLM API.
    Maintains SSE pass-through so the frontend can consume chunks in real time.
    """
    if request.method == 'OPTIONS':
        return Response(status=204)

    base_url = request.headers.get('X-LLM-Base-URL', 'https://api.openai.com/v1').rstrip('/')
    auth = request.headers.get('Authorization', '')

    target_url = f"{base_url}/chat/completions"

    headers = {
        'Content-Type': 'application/json',
        'Authorization': auth,
    }

    body = request.get_data()

    try:
        # Use stream=True so we can relay chunks incrementally
        upstream = requests.post(target_url, data=body, headers=headers, stream=True, timeout=300)

        if upstream.status_code != 200:
            # Non-streaming error — return directly
            excluded = {'content-encoding', 'content-length', 'transfer-encoding', 'connection'}
            resp_headers = {k: v for k, v in upstream.headers.items() if k.lower() not in excluded}
            return Response(upstream.content, status=upstream.status_code, headers=resp_headers)

        def generate():
            for chunk in upstream.iter_content(chunk_size=None):
                yield chunk

        resp_headers = {
            'Content-Type': 'text/event-stream',
            'Cache-Control': 'no-cache',
            'X-Accel-Buffering': 'no',
        }

        return Response(stream_with_context(generate()), status=200, headers=resp_headers)

    except requests.exceptions.Timeout:
        return jsonify({'error': 'LLM API 请求超时'}), 504
    except Exception as e:
        return jsonify({'error': str(e)}), 502


# ── Utility ──────────────────────────────────────────────────────

def find_free_port(start=18300, end=18400):
    for port in range(start, end):
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            try:
                s.bind(('127.0.0.1', port))
                return port
            except OSError:
                continue
    return start


def open_browser(port, delay=1.2):
    def _open():
        time.sleep(delay)
        webbrowser.open(f'http://127.0.0.1:{port}')
    threading.Thread(target=_open, daemon=True).start()


def main():
    port = find_free_port()
    print(f"")
    print(f"  ╔══════════════════════════════════════════╗")
    print(f"  ║   RunningHubAI 故事板生成器               ║")
    print(f"  ╚══════════════════════════════════════════╝")
    print(f"")
    print(f"  服务地址:  http://127.0.0.1:{port}")
    print(f"  前端文件:  {FRONTEND_DIR}")
    print(f"  按 Ctrl+C 停止服务")
    print(f"")

    open_browser(port)
    app.run(host='127.0.0.1', port=port, debug=False, use_reloader=False)


if __name__ == '__main__':
    main()
