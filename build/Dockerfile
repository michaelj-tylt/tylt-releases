# Stage 1: Base OS layer
FROM docker.io/ubuntu:22.04 AS base

ENV DEBIAN_FRONTEND=noninteractive
ENV DEBIAN_PRIORITY=high

RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get clean

# Stage 2: System packages layer
FROM base AS system-packages

RUN apt-get update && \
    apt-get -y install \
    # UI Requirements
    xvfb \
    xterm \
    xdotool \
    scrot \
    imagemagick \
    sudo \
    mutter \
    x11vnc \
    gnome-shell-extensions \
    # Python/pyenv reqs
    build-essential \
    libssl-dev  \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    curl \
    git \
    libncursesw5-dev \
    xz-utils \
    tk-dev \
    libxml2-dev \
    libxmlsec1-dev \
    libffi-dev \
    liblzma-dev \
    # Network tools
    net-tools \
    netcat \
    # PPA req
    software-properties-common && \
    apt-get clean

# Install Node.js 18
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean

# Install MongoDB Community Edition
# Import the public key used by the package management system
RUN curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
    gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor

# Create a list file for MongoDB
RUN echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | \
    tee /etc/apt/sources.list.d/mongodb-org-7.0.list

# Install MongoDB packages
RUN apt-get update && \
    apt-get install -y mongodb-org && \
    apt-get clean

# Create MongoDB data directory and set permissions
RUN mkdir -p /data/db /var/log/mongodb && \
    chown -R mongodb:mongodb /data/db /var/log/mongodb && \
    chmod 755 /data/db /var/log/mongodb

# Create volume for persistent MongoDB data
VOLUME ["/data/db"]

# Add mongodb user to sudo group for container startup
RUN usermod -aG sudo mongodb && \
    echo "mongodb ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Stage 3: User applications layer
FROM system-packages AS user-apps

# Install Google Chrome (which includes Chromium functionality)
RUN curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    google-chrome-stable \
    x11-apps \
    xpdf \
    tint2 \
    pcmanfm \
    unzip && \
    apt-get clean

# Create chromium-browser symlink to google-chrome for compatibility
RUN ln -sf /usr/bin/google-chrome /usr/bin/chromium && \
    ln -sf /usr/bin/google-chrome /usr/bin/chromium-browser

# Install noVNC
RUN git clone --branch v1.5.0 https://github.com/novnc/noVNC.git /opt/noVNC && \
    git clone --branch v0.12.0 https://github.com/novnc/websockify /opt/noVNC/utils/websockify && \
    ln -s /opt/noVNC/vnc.html /opt/noVNC/index.html

# Stage 4: User setup layer
FROM user-apps AS user-setup

# setup user
ENV USERNAME=tylt
ENV HOME=/home/$USERNAME
RUN useradd -m -s /bin/bash -d $HOME $USERNAME
RUN echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Create user directories that will be mounted for persistence
RUN mkdir -p $HOME/{Desktop,Documents,Downloads} && \
    mkdir -p $HOME/.config/{gtk-3.0,gtk-2.0,libreoffice,pulse,dconf} && \
    mkdir -p $HOME/.local/{share/applications,state} $HOME/.cache/{mesa_shader_cache,dconf} $HOME/.mozilla && \
    mkdir -p /tmp/{chrome-user-data,chrome-cache,chrome-crashes} && \
    # Create Chrome-specific directories to prevent permission errors
    mkdir -p $HOME/.cache/{google-chrome,chromium} && \
    mkdir -p $HOME/.config/{google-chrome,chromium} && \
    mkdir -p $HOME/.local/share/{applications,icons,mime} && \
    # Create system directories that Chrome might try to access
    mkdir -p /tmp/.org.chromium.Chromium.* 2>/dev/null || true && \
    # Fix ownership BEFORE setting permissions
    chown -R $USERNAME:$USERNAME $HOME /tmp/chrome-* && \
    # Fix permissions for all Chrome directories AFTER ownership
    chmod -R 755 $HOME/.local $HOME/.cache $HOME/.config && \
    # Create mimeapps.list with proper ownership
    touch $HOME/.local/share/applications/mimeapps.list && \
    chown $USERNAME:$USERNAME $HOME/.local/share/applications/mimeapps.list

# Disable audio/sound notifications to prevent noVNC screenshot sounds
RUN echo "# Disable system bell and audio notifications" >> $HOME/.bashrc && \
    echo "export DISPLAY=:1" >> $HOME/.bashrc && \
    echo "xset b off 2>/dev/null || true" >> $HOME/.bashrc && \
    echo "pulseaudio --kill 2>/dev/null || true" >> $HOME/.bashrc && \
    mkdir -p $HOME/.config/pulse && \
    echo "autospawn = no" > $HOME/.config/pulse/client.conf && \
    echo "daemon-binary = /bin/true" >> $HOME/.config/pulse/client.conf && \
    mkdir -p $HOME/.config/gtk-3.0 && \
    echo "[Settings]" > $HOME/.config/gtk-3.0/settings.ini && \
    echo "gtk-sound-theme-name=" >> $HOME/.config/gtk-3.0/settings.ini && \
    echo "gtk-enable-event-sounds=0" >> $HOME/.config/gtk-3.0/settings.ini && \
    echo "gtk-enable-input-feedback-sounds=0" >> $HOME/.config/gtk-3.0/settings.ini && \
    chown -R $USERNAME:$USERNAME $HOME/.config

USER tylt
WORKDIR $HOME

# Stage 5: Python environment layer
FROM user-setup AS python-env

# setup python
RUN git clone https://github.com/pyenv/pyenv.git ~/.pyenv && \
    cd ~/.pyenv && src/configure && make -C src && cd .. && \
    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc && \
    echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc && \
    echo 'eval "$(pyenv init -)"' >> ~/.bashrc
ENV PYENV_ROOT="$HOME/.pyenv"
ENV PATH="$PYENV_ROOT/bin:$PATH"
ENV PYENV_VERSION_MAJOR=3
ENV PYENV_VERSION_MINOR=11
ENV PYENV_VERSION_PATCH=6
ENV PYENV_VERSION=$PYENV_VERSION_MAJOR.$PYENV_VERSION_MINOR.$PYENV_VERSION_PATCH
RUN eval "$(pyenv init -)" && \
    pyenv install $PYENV_VERSION && \
    pyenv global $PYENV_VERSION && \
    pyenv rehash

ENV PATH="$HOME/.pyenv/shims:$HOME/.pyenv/bin:$PATH"

# Stage 6: Pip and base packages layer
FROM python-env AS pip-setup

RUN python -m pip install --upgrade pip==23.1.2 setuptools==58.0.4 wheel==0.40.0 && \
    python -m pip config set global.disable-pip-version-check true

# Stage 7: Python dependencies layer
FROM pip-setup AS python-deps

# Install Python dependencies
COPY --chown=$USERNAME:$USERNAME app/image/$MSASS/agent/requirements.txt $HOME/agent/requirements.txt
RUN python -m pip install -r $HOME/agent/requirements.txt

# Stage 8: Node.js dependencies layer
FROM python-deps AS nodejs-deps

# Install Next.js dependencies
COPY --chown=$USERNAME:$USERNAME app/image/$MSASS/frontend/package*.json $HOME/nextjs/
WORKDIR $HOME/nextjs
RUN npm install --legacy-peer-deps

# Stage 9: Application layer (final)
FROM nodejs-deps AS app

# Create directories for mounted volumes
RUN mkdir -p $HOME/agent $HOME/nextjs $HOME/image && \
    chown -R $USERNAME:$USERNAME $HOME/agent $HOME/nextjs $HOME/image

# Build Next.js app (conditionally)  
WORKDIR $HOME/nextjs

# Copy image directory with scripts and configs first
COPY --chown=$USERNAME:$USERNAME app/image/ /home/tylt/image/
# Copy environment file if it exists
COPY --chown=$USERNAME:$USERNAME .env.local /home/tylt/.env.local 2>/dev/null || true
# Copy repositories for development mode
COPY --chown=$USERNAME:$USERNAME app/image/$MSASS/frontend/ /home/tylt/staging/tylt-frontend/
COPY --chown=$USERNAME:$USERNAME app/image/$MSASS/agent/ /home/tylt/staging/tylt-agent/
# Set build-time environment variables
ENV NEXT_PUBLIC_API_URL=http://localhost:8000

# Add build arguments for development mode and microsass selection
ARG DEV_MODE=false
ARG MSASS=tester
RUN echo "Building for microsass: $MSASS" && \
    if [ "$DEV_MODE" = "false" ]; then \
        echo "Production mode - using included source code"; \
        cp -r /home/tylt/image/$MSASS/frontend/. /home/tylt/nextjs/ && \
        cp -r /home/tylt/image/$MSASS/agent/. /home/tylt/agent/ && \
        chown -R $USERNAME:$USERNAME /home/tylt/nextjs /home/tylt/agent; \
    else \
        echo "Development mode - will install dependencies and run dev server at runtime"; \
        cp -r /home/tylt/staging/tylt-frontend/. /home/tylt/nextjs/ && \
        cp -r /home/tylt/staging/tylt-agent/. /home/tylt/agent/ && \
        mkdir -p .next && chown -R $USERNAME:$USERNAME /home/tylt/nextjs /home/tylt/agent .next; \
    fi && \
    if [ -f /home/tylt/.env.local ]; then \
        cp /home/tylt/.env.local /home/tylt/nextjs/.env.local 2>/dev/null || true; \
    fi

WORKDIR $HOME

ARG DISPLAY_NUM=1
ARG HEIGHT=768
ARG WIDTH=1024
ENV DISPLAY_NUM=$DISPLAY_NUM
ENV HEIGHT=$HEIGHT
ENV WIDTH=$WIDTH
ENV MSASS=$MSASS

# Expose ports
EXPOSE 3001 8501 6080 27017

ENTRYPOINT [ "./image/entrypoint.sh" ]