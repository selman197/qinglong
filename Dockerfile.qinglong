Stage 1: 拿到官方青龙 /ql 全套脚本
FROM whyour/qinglong:latest AS ql

Stage 2: Ubuntu 基础运行环境
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive TZ=Asia/Shanghai LANG=C.UTF-8 LC_ALL=C.UTF-8

基础依赖 + Node.js 20 + pm2 + Python + docker-cli + 运行工具
RUN apt-get update && apt-get install -y --no-install-recommends
ca-certificates curl wget unzip gnupg apt-transport-https
bash git jq iproute2 procps coreutils sed grep openssl
nginx cron busybox
python3 python3-pip build-essential
&& curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
&& apt-get update && apt-get install -y --no-install-recommends nodejs
&& npm install -g pm2
&& apt-get install -y --no-install-recommends docker.io
&& rm -rf /var/lib/apt/lists/*

复制官方青龙的 /ql 全部文件，确保 entrypoint 可用
COPY --from=ql /ql /ql

兼容 entrypoint 中的 crond 调用（Ubuntu 中是 /usr/sbin/cron）
RUN ln -sf /usr/sbin/cron /usr/sbin/crond

暴露面板端口
EXPOSE 5700

缺省以 root 运行，便于访问 /var/run/docker.sock
ENTRYPOINT ["/bin/bash", "/ql/docker/docker-entrypoint.sh"]
