# Tylt Releases

This repository contains official releases of the Tylt project.

## Latest Release

**v0.0.71** - Complete agent stop/resume functionality and fix critical issues

### Docker Images

**Linux x86_64:**
```bash
docker pull gotylt/tylt-sidekick-app-linux:0.0.71
docker pull gotylt/tylt-sidekick-app-linux:latest
```

**ARM64 (Mac/Linux):**
```bash
docker pull gotylt/tylt-sidekick-app-arm64:0.0.71
docker pull gotylt/tylt-sidekick-app-arm64:latest
```

**Windows:**
```bash
docker pull gotylt/tylt-sidekick-app-windows:0.0.71
docker pull gotylt/tylt-sidekick-app-windows:latest
```

### Quick Start

```bash
# Run latest release
docker run -p 6080:6080 -p 3001:3001 gotylt/tylt-sidekick-app-linux:latest

# Access the application
# Frontend: http://localhost:3001
# VNC Web: http://localhost:6080
```

## Building from Source

### Requirements
- Docker
- Git

### Build Scripts
```bash
# Linux/Mac
./build/build.sh prod

# Windows
.\build\build.ps1

# Release to DockerHub
MSASS=sidekick ./build/release.sh 0.0.71
```

### Run Scripts
```bash
# Linux/Mac
./run.sh

# Windows  
.\run.ps1
```

## Architecture

This follows the **tylt** → **msass** → **environment** structure:
- **tylt**: Main product
- **sidekick**: Microsass (multi-tenant service)  
- **dev/test/prod/stage**: Environment

## Release History

See [Releases](../../releases) for full changelog and download links.