# 下面生成一个完整的Dockerfile内容，基于Ubuntu 20.04，集成：
# - 青龙面板（从whyour/qinglong官方GitHub源码安装）
# - Chrome稳定版浏览器及对应chromedriver版本（版本匹配）
# - 完整Python3环境及selenium、requests等必备包
# - Node.js（官方18.x版）和npm，及selenium-webdriver包
# - 所需的各种Linux依赖包，确保兼容和稳定运行

dockerfile = """
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV TZ=Asia/Shanghai

# 基础依赖及工具
RUN apt-get update && apt-get install -y --no-install-recommends \\
    apt-transport-https \\
    ca-certificates \\
    curl \\
    wget \\
    unzip \\
    gnupg2 \\
    software-properties-common \\
    fonts-liberation \\
    libatk-bridge2.0-0 \\
    libx11-xcb1 \\
    libgtk-3-0 \\
    libxss1 \\
    libnss3 \\
    libasound2 \\
    lsb-release \\
    xdg-utils \\
    libcairo2 \\
    libdbus-1-3 \\
    libexpat1 \\
    libfontconfig1 \\
    libgbm1 \\
    libglib2.0-0 \\
    libpango-1.0-0 \\
    libpangocairo-1.0-0 \\
    fonts-noto-color-emoji \\
    libxcomposite1 \\
    libxcursor1 \\
    libxdamage1 \\
    libxfixes3 \\
    libxi6 \\
    libxtst6 \\
    x11-utils \\
    procps \\
    build-essential \\
    gcc \\
    g++ \\
    make \\
    python3 \\
    python3-dev \\
    python3-pip \\
    python3-setuptools \\
    git \\
    nano \\
    && rm -rf /var/lib/apt/lists/*

# 安装Google Chrome稳定版
RUN curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | apt-key add - \\
    && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \\
    && apt-get update \\
    && apt-get install -y google-chrome-stable \\
    && rm -rf /var/lib/apt/lists/*

# 安装对应版本chromedriver（自动匹配chrome主版本）
RUN CHROME_VERSION=$(google-chrome --product-version | grep -oE '^[0-9]+') \\
    && CHROMEDRIVER_VERSION=$(curl -sS https://chromedriver.storage.googleapis.com/LATEST_RELEASE_${CHROME_VERSION}) \\
    && wget -O /tmp/chromedriver_linux64.zip https://chromedriver.storage.googleapis.com/${CHROMEDRIVER_VERSION}/chromedriver_linux64.zip \\
    && unzip /tmp/chromedriver_linux64.zip -d /usr/local/bin/ \\
    && rm /tmp/chromedriver_linux64.zip \\
    && chmod +x /usr/local/bin/chromedriver

# 安装Python依赖：selenium、requests
RUN pip3 install --no-cache-dir --upgrade pip \\
    && pip3 install --no-cache-dir selenium requests cloudscraper pyppeteer

# 安装Node.js 18.x及npm，并安装selenium-webdriver
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \\
    && apt-get install -y nodejs \\
    && npm install -g npm@latest selenium-webdriver \\
    && rm -rf /var/lib/apt/lists/*

# 克隆并安装青龙面板（注意：这里使用官方源码安装最新版本）
WORKDIR /ql
RUN git clone --depth=1 https://github.com/whyour/qinglong.git . \\
    && bash scripts/install.sh

# 环境变量设置（可选）
ENV CHROME_PATH=/usr/bin/google-chrome
ENV CHROMEDRIVER_PATH=/usr/local/bin/chromedriver
ENV PATH=$PATH:/usr/local/bin

# 暴露青龙默认端口
EXPOSE 5700

# 启动青龙面板
ENTRYPOINT ["/bin/bash", "/ql/docker/docker-entrypoint.sh"]
"""

print(dockerfile)
