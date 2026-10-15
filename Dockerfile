# syntax=docker/dockerfile:1
# ============================================================
# Tabbit2API 容器镜像（amd64 / arm64 通用）
# 构建:  docker build -t tabbit2api .
# 运行:  docker run -d -p 8123:8123 -v tabbit2api-data:/app/data tabbit2api
# ============================================================

FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PLAYWRIGHT_BROWSERS_PATH=/ms-playwright

WORKDIR /app

# 1) 安装 Python 依赖（独立 COPY 以利用层缓存）
COPY requirements.txt .
RUN pip install --upgrade pip \
    && pip install -r requirements.txt

# 2) 安装 Playwright Chromium 及系统依赖
#    --with-deps 自动补齐浏览器运行所需的系统库；arm64 下自动下载对应架构浏览器
RUN playwright install --with-deps chromium

# 3) 拷贝项目源码
COPY . .

# 4) 数据目录：调用记录 usage.json 等持久化于此
RUN mkdir -p /app/data
VOLUME ["/app/data"]

EXPOSE 8123

# 健康检查复用 /health 端点，用 Python 实现避免额外安装 curl
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD ["python", "-c", "import sys,urllib.request; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:8123/health',timeout=5).status==200 else 1)"]

CMD ["python", "start.py"]
