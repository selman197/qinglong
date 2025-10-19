FROM whyour/qinglong:latest

# 安装必要的系统工具和尽可能全面的依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    curl \
    unzip \
    gnupg2 \
    ca-certificates \
    fonts-liberation \
    libatk-bridge2.0-0 \
    libx11-xcb1 \
    libgtk-3-0 \
    libxss1 \
    libnss3 \
    libasound2 \
    lsb-release \
    xdg-utils \
    libcairo2 \
    libdbus-1-3 \
    libexpat1 \
    libfontconfig1 \
    libgbm1 \
    libglib2.0-0 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    fonts-noto-color-emoji \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxfixes3 \
    libxi6 \
    libxtst6 \
    x11-utils \
    procps \
    ca-certificates \
    software-properties-common \
    build-essential \
    gcc \
    g++ \
    make \
    python3-dev \
    python3-pip \
    python3-setuptools \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# 升级pip，并安装Python包：selenium==4.0.0（版本兼容），requests，pyppeteer，cloudscraper
RUN pip3 install --no-cache-dir --upgrade pip \
    && pip3 install --no-cache-dir selenium==4.0.0 requests pyppeteer cloudscraper

# 安装稳定版Google Chrome浏览器
RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# 安装对应版本ChromeDriver（版本与Chrome保持一致）
RUN CHROME_VERSION=$(google-chrome --product-version | grep -oE '^[0-9]+') \
    && CHROMEDRIVER_VERSION=$(curl -sS https://chromedriver.storage.googleapis.com/LATEST_RELEASE_$CHROME_VERSION) \
    && wget -O /tmp/chromedriver_linux64.zip https://chromedriver.storage.googleapis.com/$CHROMEDRIVER_VERSION/chromedriver_linux64.zip \
    && unzip /tmp/chromedriver_linux64.zip -d /usr/local/bin/ \
    && rm /tmp/chromedriver_linux64.zip \
    && chmod +x /usr/local/bin/chromedriver

# 使用官方Node.js源安装较新版本Node.js，升级npm并安装selenium-webdriver包
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g npm@latest \
    && npm install -g selenium-webdriver

# 设置环境变量（可选）
ENV CHROME_PATH=/usr/bin/google-chrome
ENV CHROMEDRIVER_PATH=/usr/local/bin/chromedriver
ENV NODE_PATH=/usr/bin/node
ENV NPM_PATH=/usr/bin/npm

# 暴露青龙面板端口
EXPOSE 5700

# 保持青龙官方默认入口
ENTRYPOINT ["/bin/bash", "/ql/docker/docker-entrypoint.sh"]