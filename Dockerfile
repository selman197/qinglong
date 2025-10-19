FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive TZ=Asia/Shanghai LANG=C.UTF-8 LC_ALL=C.UTF-8

# 基础依赖和 Chrome 运行库
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl wget unzip gnupg gnupg2 apt-transport-https \
    fonts-liberation fonts-noto-color-emoji \
    libatk-bridge2.0-0 libx11-xcb1 libgtk-3-0 libxss1 libnss3 libasound2 \
    lsb-release xdg-utils libcairo2 libdbus-1-3 libexpat1 libfontconfig1 \
    libgbm1 libglib2.0-0 libpango-1.0-0 libpangocairo-1.0-0 \
    libxcomposite1 libxcursor1 libxdamage1 libxfixes3 libxi6 libxtst6 \
    x11-utils procps build-essential gcc g++ make \
    python3 python3-dev python3-pip python3-setuptools git nano \
    && rm -rf /var/lib/apt/lists/*

# 固定 Chrome for Testing 版本
ENV CHROME_FOR_TESTING_VERSION=141.0.7390.78

# 安装 Chrome
RUN wget -O /tmp/chrome-linux64.zip https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-testing/${CHROME_FOR_TESTING_VERSION}/linux64/chrome-linux64.zip \
    && unzip /tmp/chrome-linux64.zip -d /opt/ \
    && rm /tmp/chrome-linux64.zip \
    && ln -s /opt/chrome-linux64/google-chrome /usr/bin/google-chrome

# 安装 chromedriver（修复路径）
RUN wget -O /tmp/chromedriver-linux64.zip https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-testing/${CHROME_FOR_TESTING_VERSION}/linux64/chromedriver-linux64.zip \
    && unzip /tmp/chromedriver-linux64.zip -d /tmp/ \
    && mv /tmp/chromedriver-linux64/chromedriver /usr/local/bin/chromedriver \
    && rm -rf /tmp/chromedriver-linux64 /tmp/chromedriver-linux64.zip \
    && chmod +x /usr/local/bin/chromedriver

# Python 依赖
RUN pip3 install --no-cache-dir --upgrade pip \
    && pip3 install --no-cache-dir \
       selenium requests pyppeteer cloudscraper \
       beautifulsoup4 lxml pandas numpy tqdm

# 安装 Node.js 20.x + 最新 npm
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get update && apt-get install -y --no-install-recommends nodejs \
    && npm install -g npm@latest selenium-webdriver axios puppeteer lodash moment \
    && rm -rf /var/lib/apt/lists/*

# 安装青龙面板
WORKDIR /ql
RUN git clone --depth=1 https://github.com/whyour/qinglong.git . \
    && bash scripts/install.sh

# 环境变量
ENV CHROME_PATH=/usr/bin/google-chrome CHROMEDRIVER_PATH=/usr/local/bin/chromedriver PATH=$PATH:/usr/local/bin

EXPOSE 5700
ENTRYPOINT ["/bin/bash", "/ql/docker/docker-entrypoint.sh"]
