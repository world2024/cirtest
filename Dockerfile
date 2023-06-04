FROM node:slim
EXPOSE 3000
WORKDIR /app
# COPY . .
# COPY web.js /app/web.js
COPY server.js /app/server.js
COPY package.json /app/package.json
COPY entrypoint.sh /app/entrypoint.sh

ENV TZ="Asia/Shanghai"
ENV NODE_ENV="production"

# Install dependencies
RUN apt-get update &&\
  apt-get install -y iproute2 unzip coreutils curl wget openssh-server &&\
  # Clean up APT when done.
  apt-get clean &&\
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* &&\
  # Install cloudflared
  wget -nv -O cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 &&\
  mv cloudflared /usr/local/bin &&\
  # Install XrayR
  wget -nv -O /tmp/apps.zip https://github.com/XrayR-project/XrayR/releases/latest/download/XrayR-linux-64.zip && \
  mkdir /app/apps && \
  unzip -d /app/apps /tmp/apps.zip && \
  mv /app/apps/XrayR /app/apps/myapps.js && \
  rm -rf /app/apps/README.md && \
  rm -rf /app/apps/LICENSE && \
  rm -rf /app/apps/config.yml && \
  rm -f /tmp/apps.zip && \
  # Install nodejs dependencies
  npm install -r package.json &&\
  # npm install -g pm2 &&\
  npm run build &&\
  # Install Xray-core
  wget -nv -O core.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && \
  unzip -qod ./ core.zip && \
  rm -f core.zip && \
  rm -rf geoip.dat && \
  rm -rf geosite.dat && \
  rm -rf LICENSE && \
  rm -rf README.md && \
  mv xray web.js && \
  # Install Nezha
  wget -t 2 -T 10 -N https://github.com/nezhahq/agent/releases/latest/download/nezha-agent_linux_amd64.zip &&\
  unzip -qod ./ nezha-agent_linux_amd64.zip &&\
  rm -f nezha-agent_linux_amd64.zip &&\
  # Set permissions
  chmod +x /usr/local/bin/cloudflared &&\
  chmod +x /app/apps/myapps.js &&\
  chmod +x /app/nezha-agent &&\
  chmod +x /app/entrypoint.sh &&\
  chmod +x web.js &&\
  # Set root password and enable password login  
  echo 'root:password' | chpasswd &&\
  sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config &&\
  sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

# 健康检查
HEALTHCHECK --interval=2m --timeout=30s \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000
# 启动命令
ENTRYPOINT ["npm", "start"]
