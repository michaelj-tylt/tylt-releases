# Changelog

All notable changes to Tylt releases will be documented in this file.

## [v0.0.71] - 2025-08-13

### 🎉 Major Features
- **Complete Agent Stop/Resume Functionality**: Proper pause/resume with instant UI feedback
- **Chat History Preservation**: Messages no longer clear when resuming from pause
- **v3 API Migration**: All endpoints consistently use v3 API architecture

### 🐛 Critical Bug Fixes
- **Fixed 500 Internal Server Errors**: Resolved malformed tool result content structure
- **Eliminated Screenshot Beeping**: Added `xset b off` and `--no-flash` flags
- **Browser Persistence**: Browser now stays open after task completion for result inspection
- **Agent Auto-restart Bug**: Fixed TaskRunner incorrectly restarting execution on resume

### 🏗️ Technical Improvements
- **Replaced Global Variables**: Eliminated terrible `_agent_stop_flag` with proper `AgentController` class
- **Thread-safe Architecture**: Implemented proper `asyncio.Event` for pause/resume control
- **Server-side Logging**: Added v3/debug API route replacing client console.log spam
- **MSASS Support**: Added multi-tenant architecture support to release scripts
- **Tool Result Validation**: Enhanced validation to prevent empty content causing API errors

### 🛠️ Infrastructure
- **Multi-platform Docker Images**: 
  - `gotylt/tylt-sidekick-app-linux:0.0.71` (x86_64)
  - `gotylt/tylt-sidekick-app-arm64:0.0.71` (ARM64 Mac/Linux)
  - `gotylt/tylt-sidekick-app-windows:0.0.71` (Windows)
- **Production-ready Configuration**: All images default to production mode
- **Proper Release Repository**: Separated release artifacts from development code

### 📱 User Experience
- **Immediate UI Feedback**: Stop button reacts instantly before API calls
- **Clear Pause Messages**: Updated to say "send a new message to continue"
- **Preserved Conversations**: Chat history maintained across pause/resume cycles
- **Clean Browser Management**: No premature cleanup during task execution

### 🔧 Breaking Changes
- Agent control now uses proper `AgentController` instead of global variables
- v3 API endpoints replace mixed v1/v2/v3 usage
- Release scripts now require `MSASS` parameter for proper image naming

---

## Docker Images

All images are available on DockerHub with both versioned and `latest` tags:

```bash
# Pull specific version
docker pull gotylt/tylt-sidekick-app-linux:0.0.71

# Pull latest 
docker pull gotylt/tylt-sidekick-app-linux:latest
```