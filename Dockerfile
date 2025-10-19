FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Shanghai \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    CHROME_FOR_TESTING_VERSION=141.0.7390.78

# 一次性安装所有系统依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl wget unzip gnupg gnupg2 apt-transport-https \
    fonts-liberation fonts-noto-color-emoji \
    libatk-bridge2.0-0 libx11-xcb1 libgtk-3-0 libxss1 libnss3 libasound2 \
    lsb-release xdg-utils libcairo2 libdbus-1-3 libexpat1 libfontconfig1 \
    libgbm1 libglib2.0-0 libpango-1.0-0 libpangocairo-1.0-0 \
    libxcomposite1 libxcursor1 libxdamage1 libxfixes3 libxi6 libxtst6 \
    x11-utils procps build-essential gcc g++ make \
    python3 python3-dev python3-pip python3-setuptools git nano \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# 安装 Chrome 和 Chromedriver
RUN set -eux; \
    # 安装 Chrome
    wget -q --show-progress --progress=bar:force -O /tmp/chrome-linux64.zip \
        https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-testing/${CHROME_FOR_TESTING_VERSION}/linux64/chrome-linux64.zip && \
    unzip -q /tmp/chrome-linux64.zip -d /opt/ && \
    rm /tmp/chrome-linux64.zip && \
    ln -sf /opt/chrome-linux64/google-chrome /usr/bin/google-chrome && \
    \
    # 安装 Chromedriver
    wget -q --show-progress --progress=bar:force -O /tmp/chromedriver-linux64.zip \
        https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-testing/${CHROME_FOR_TESTING_VERSION}/linux64/chromedriver-linux64.zip && \
    unzip -q /tmp/chromedriver-linux64.zip -d /tmp/ && \
    mv /tmp/chromedriver-linux64/chromedriver /usr/local/bin/chromedriver && \
    rm -rf /tmp/chromedriver-linux64 /tmp/chromedriver-linux64.zip && \
    chmod +x /usr/local/bin/chromedriver

# 安装 Python 和 Node.js 依赖
RUN pip3 install --no-cache-dir --upgrade pip && \
    pip3 install --no-cache-dir \
        selenium requests pyppeteer cloudscraper \
        beautifulsoup4 lxml pandas numpy tqdm && \
    \
    # 安装 Node.js
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get update && apt-get install -y --no-install-recommends nodejs && \
    npm install -g npm@latest selenium-webdriver axios puppeteer lodash moment && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

# 设置工作目录并安装青龙
WORKDIR /ql
RUN git clone --depth=1 https://github.com/whyour/qinglong.git . && \
    curl -fsSL https://raw.githubusercontent.com/shufflewzc/QLDependency/main/Shell/QLOneKeyDependency.sh | bash

# 环境变量
ENV CHROME_PATH=/usr/bin/google-chrome \
    CHROMEDRIVER_PATH=/usr/local/bin/chromedriver \
    PATH="/usr/local/bin:${PATH}"

EXPOSE 5700
ENTRYPOINT ["/bin/bash", "/ql/docker/docker-entrypoint.sh"]
