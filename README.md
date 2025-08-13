# Tylt Releases

Official production releases of Tylt - Intelligent Desktop Automation with AI.

## Latest Release: v0.0.1

Initial production release with complete agent stop/resume functionality and critical bug fixes.

## Quick Start (Production)

### Option 1: Docker Compose (Recommended)
```bash
# Download and run
curl -O https://raw.githubusercontent.com/michaelj-tylt/tylt-releases/main/docker-compose.yml
docker-compose up -d

# Access the application
# Frontend: http://localhost:3001
# VNC Web: http://localhost:6080
```

### Option 2: Direct Docker Run
```bash
# Linux x86_64
docker run -d --name tylt-sidekick \
  -p 3001:3001 -p 6080:6080 -p 8000:8000 \
  -v $(pwd)/user_data:/home/tylt/user_data \
  -v $(pwd)/logs:/home/tylt/logs \
  -v $(pwd)/db_data:/data/db \
  gotylt/tylt-sidekick-app-linux:latest

# ARM64 (Mac/Linux)  
docker run -d --name tylt-sidekick \
  -p 3001:3001 -p 6080:6080 -p 8000:8000 \
  -v $(pwd)/user_data:/home/tylt/user_data \
  -v $(pwd)/logs:/home/tylt/logs \
  -v $(pwd)/db_data:/data/db \
  gotylt/tylt-sidekick-app-arm64:latest

# Windows
docker run -d --name tylt-sidekick \
  -p 3001:3001 -p 6080:6080 -p 8000:8000 \
  -v %cd%/user_data:/home/tylt/user_data \
  -v %cd%/logs:/home/tylt/logs \
  -v %cd%/db_data:/data/db \
  gotylt/tylt-sidekick-app-windows:latest
```

## Available Images

| Platform | Image | Size |
|----------|-------|------|
| Linux x86_64 | `gotylt/tylt-sidekick-app-linux:0.0.71` | 5.79GB |
| ARM64 (Mac/Linux) | `gotylt/tylt-sidekick-app-arm64:0.0.71` | 5.79GB |
| Windows | `gotylt/tylt-sidekick-app-windows:0.0.71` | 5.79GB |

## Configuration

1. **Copy environment template:**
   ```bash
   curl -O https://raw.githubusercontent.com/michaelj-tylt/tylt-releases/main/.env.example
   cp .env.example .env
   ```

2. **Edit `.env` with your settings:**
   - Add your `ANTHROPIC_API_KEY`
   - Customize `MSASS` if needed (default: sidekick)

3. **Run with environment:**
   ```bash
   docker-compose --env-file .env up -d
   ```

## Features

- **Computer Use Automation:** Screenshot capture and desktop interaction
- **AI Chat Integration:** Support for Anthropic, Bedrock, Vertex AI
- **Task Execution:** Step-by-step workflow automation
- **Network & JS Inspection:** Debug web applications and network traffic
- **VNC Access:** Remote desktop control via web browser
- **Multi-tenant Architecture:** Support for multiple microsass instances

## Ports

- **3001:** Frontend web interface
- **6080:** VNC web access (noVNC)
- **8000:** API service
- **5900:** VNC direct access
- **27017:** MongoDB database

## Data Persistence

The following directories are mounted for data persistence:
- `./user_data` - User files and application data
- `./logs` - Application logs
- `./db_data` - MongoDB database files

## Release History

See [Releases](../../releases) for detailed changelog and download links.