# Run script for Tylt on Windows PowerShell

# Error handling
$ErrorActionPreference = "Stop"

# Function to check if Docker Desktop is installed and running
function Test-DockerDesktop {
    # Check if Docker Desktop is installed
    $dockerDesktopPath = Get-Command "Docker Desktop" -ErrorAction SilentlyContinue
    if (-not $dockerDesktopPath) {
        # Try alternative paths
        $possiblePaths = @(
            "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe",
            "$env:LOCALAPPDATA\Docker\Docker Desktop.exe"
        )
        
        $dockerDesktopPath = $possiblePaths | Where-Object { Test-Path $_ } | Select-Object -First 1
        
        if (-not $dockerDesktopPath) {
            Write-Host "❌ Docker Desktop is not installed!" -ForegroundColor Red
            Write-Host ""
            Write-Host "To run Tylt, you need Docker Desktop installed:" -ForegroundColor Yellow
            Write-Host "1. Download Docker Desktop from: https://www.docker.com/products/docker-desktop/" -ForegroundColor Yellow
            Write-Host "2. Install and restart your computer" -ForegroundColor Yellow
            Write-Host "3. Start Docker Desktop and complete the setup" -ForegroundColor Yellow
            Write-Host "4. Run this script again" -ForegroundColor Yellow
            exit 1
        }
    }
    
    # Check if Docker daemon is running
    try {
        docker version | Out-Null
        return $true
    }
    catch {
        # Docker Desktop installed but not running
        Write-Host "⚠️  Docker Desktop is installed but not running" -ForegroundColor Yellow
        Write-Host "Starting Docker Desktop..."
        
        if ($dockerDesktopPath -is [string]) {
            Start-Process -FilePath $dockerDesktopPath -WindowStyle Hidden
        } else {
            Start-Process -FilePath "Docker Desktop" -WindowStyle Hidden
        }
        
        # Wait for Docker to start
        Write-Host "Waiting for Docker Desktop to start..."
        for ($i = 1; $i -le 60; $i++) {
            try {
                docker version | Out-Null
                Write-Host "✅ Docker Desktop is now running!" -ForegroundColor Green
                return $true
            }
            catch {
                Write-Host "." -NoNewline
                Start-Sleep -Seconds 2
            }
        }
        
        Write-Host ""
        Write-Host "❌ Docker Desktop failed to start within 2 minutes" -ForegroundColor Red
        Write-Host "Please start Docker Desktop manually and try again" -ForegroundColor Yellow
        exit 1
    }
}

# Check Docker Desktop before proceeding
Test-DockerDesktop

# Load environment variables from .env.local
if (Test-Path ".env.local") {
    Get-Content ".env.local" | ForEach-Object {
        if ($_ -match "^([^#][^=]*?)\s*=\s*(.*?)$") {
            Set-Variable -Name $matches[1] -Value $matches[2] -Scope Global
        }
    }
    Write-Host "Loaded environment variables from .env.local"
} else {
    Write-Host "Warning: .env.local file not found"
}

# Set default MSASS if not specified
if (-not $MSASS) {
    $MSASS = "tester"
}
Write-Host "Running microsass: $MSASS"

# Parse command line arguments
$DevMode = $args[0] -eq "dev"

# Clear logs directory
if (Test-Path "logs") {
    Remove-Item -Path "logs\*" -Recurse -Force
}
New-Item -ItemType Directory -Path "logs" -Force | Out-Null

if ($DevMode) {
    Write-Host "Starting Tylt in development mode for microsass: $MSASS"
} else {
    Write-Host "Starting Tylt in production mode for microsass: $MSASS"
}

# Load .env.local file if it exists
if (Test-Path ".env.local") {
    Write-Host "Loading environment variables from .env.local..."
    Get-Content ".env.local" | Where-Object { $_ -notmatch '^#' -and $_ -match '=' } | ForEach-Object {
        $parts = $_ -split '=', 2
        if ($parts.Length -eq 2) {
            [Environment]::SetEnvironmentVariable($parts[0].Trim(), $parts[1].Trim())
        }
    }
}

if ($DevMode) {
    $IMAGE_NAME = "tylt-dev-windows:latest"
} else {
    $IMAGE_NAME = "tylt-app-windows:latest"
}

# Create db_data directory if it doesn't exist (separate for each MSASS)
if (!(Test-Path "db_data_$MSASS")) {
    New-Item -ItemType Directory -Path "db_data_$MSASS" | Out-Null
}

# Stop and remove any existing Tylt containers
Write-Host "Stopping any existing Tylt containers..."
# Stop all containers from tylt images
$containers = docker ps -q --filter "ancestor=tylt-app-windows" --filter "ancestor=tylt-dev-windows"
if ($containers) {
    docker stop $containers
    docker rm $containers
}
# Also clean up any containers that might be using our ports
$allContainers = docker ps -q
foreach ($container in $allContainers) {
    $ports = docker port $container 2>$null
    if ($ports -and ($ports -match ":3001|:8000|:5900|:6080")) {
        docker stop $container 2>$null
    }
}

# Get current directory for volume mounts
$CURRENT_DIR = (Get-Location).Path

# Check if image exists
$imageExists = docker images -q "$IMAGE_NAME" 2>$null
if (-not $imageExists) {
    if ($DevMode) {
        Write-Host "Development image not found. Building..."
        & ".\build.ps1" "dev"
    } else {
        Write-Host "Production image not found. Pulling from Docker Hub..."
        docker pull "gotylt/$IMAGE_NAME"
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Pull failed! Falling back to local build..."
            & ".\build.ps1"
        } else {
            # Tag the pulled image with our local name
            docker tag "gotylt/$IMAGE_NAME" "$IMAGE_NAME"
        }
    }
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Setup failed!"
        exit $LASTEXITCODE
    }
}

if ($DevMode) {
    Write-Host "Starting development container..."
    Write-Host "- Frontend: Local source with hot reloading"
    Write-Host "- Backend: Production configuration"
} else {
    Write-Host "Starting production container..."
    Write-Host "- Frontend: Pre-built and optimized"
    Write-Host "- Backend: Production configuration"
}

# Build docker command with conditional volume mount
$dockerArgs = @(
    "run"
    "-e", "DEV_MODE=$($DevMode.ToString().ToLower())"
    "-v", "$CURRENT_DIR\user_data:/home/tylt/user_data"
    "-v", "$CURRENT_DIR\user_data\.mozilla:/home/tylt/.mozilla"
    "-v", "$CURRENT_DIR\user_data\.config\gtk-3.0:/home/tylt/.config/gtk-3.0"
    "-v", "$CURRENT_DIR\user_data\.config\gtk-2.0:/home/tylt/.config/gtk-2.0"
    "-v", "$CURRENT_DIR\user_data\.config\libreoffice:/home/tylt/.config/libreoffice"
    "-v", "$CURRENT_DIR\user_data\.config\pulse:/home/tylt/.config/pulse"
    "-v", "$CURRENT_DIR\user_data\.local:/home/tylt/.local"
    "-v", "$CURRENT_DIR\user_data\.cache:/home/tylt/.cache"
    "-v", "$CURRENT_DIR\user_data\Desktop:/home/tylt/Desktop"
    "-v", "$CURRENT_DIR\user_data\Documents:/home/tylt/Documents"
    "-v", "$CURRENT_DIR\user_data\Downloads:/home/tylt/Downloads"
    "-v", "$CURRENT_DIR\logs:/home/tylt/logs"
    "-v", "$CURRENT_DIR\db_data_$MSASS:/data/db"
    "-v", "$CURRENT_DIR\image:/home/tylt/image"
)

# Add dev mode volume mounts - separate mount for nextjs for better file watching
if ($DevMode) {
    $dockerArgs += "-v", "$CURRENT_DIR\image\$MSASS\frontend:/home/tylt/nextjs-dev"
}

$dockerArgs += @(
    "-e", "MSASS=$MSASS"
    "-e", "DEV_MODE=$($DevMode.ToString().ToLower())"
    "-p", "5900:5900"
    "-p", "3001:3001"
    "-p", "6080:6080"
    "-p", "8000:8000"
    "-p", "27017:27017"
    "-it", "$IMAGE_NAME"
)

docker @dockerArgs

Write-Host ""
if ($DevMode) {
    Write-Host "➡️  Development server started!"
} else {
    Write-Host "➡️  Production server started!"
}
Write-Host "➡️  Frontend: http://localhost:3001"
Write-Host "➡️  Backend API: http://localhost:8000"
Write-Host "➡️  VNC Web: http://localhost:6080"
Write-Host ""
Write-Host "Container stopped."