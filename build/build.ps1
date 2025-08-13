# Build script for Tylt on Windows PowerShell

# Error handling
$ErrorActionPreference = "Stop"

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
Write-Host "Building microsass: $MSASS"

# Check for dev parameter
$DevMode = $args[0] -eq "dev"

if ($DevMode) {
    Write-Host "=== Building Tylt (Development mode) ==="
} else {
    Write-Host "=== Building Tylt (Production mode) ==="
}
Write-Host "Detected platform: Windows"

if ($DevMode) {
    $IMAGE_TAG = "tylt-dev-windows"
    $DOCKERFILE = "Dockerfile.windows"
    Write-Host "Using Windows development build"
    Write-Host "- Frontend will use 'npm run dev' (hot reloading)"
    Write-Host "- Python will run with dev settings"
} else {
    $IMAGE_TAG = "tylt-app-windows"
    $DOCKERFILE = "Dockerfile.windows"
    Write-Host "Using Windows build"
    Write-Host "- Frontend will be pre-built with 'npm run build'"
    Write-Host "- Python will run with optimized settings"
}

if (-not $DevMode) {
    # Ensure database directory exists for production (separate for each MSASS)
    if (-not (Test-Path "db_data_$MSASS")) {
        New-Item -ItemType Directory -Path "db_data_$MSASS" | Out-Null
        Write-Host "Created database directory for $MSASS"
    }

    # Build Next.js for production
    Write-Host "Building Next.js for production..."
    Push-Location "image\$MSASS\frontend"
    try {
        npm install --legacy-peer-deps
        npm run build
    } finally {
        Pop-Location
    }
} else {
    # Development mode - just ensure directories exist (separate for each MSASS)
    Write-Host "Setting up development environment..."
    if (-not (Test-Path "db_data_$MSASS")) {
        New-Item -ItemType Directory -Path "db_data_$MSASS" | Out-Null
    }
    Write-Host "Development setup complete"
}

# Build with BuildKit for better caching
Write-Host "Building Docker image ($IMAGE_TAG)..."
$env:DOCKER_BUILDKIT = "1"

# Build the Docker image
docker build `
    --target app `
    --tag "$($IMAGE_TAG):latest" `
    --file "build\$DOCKERFILE" `
    --build-arg "DEV_MODE=$($DevMode.ToString().ToLower())" `
    --build-arg "MSASS=$MSASS" `
    --build-arg "DISPLAY_NUM=1" `
    --build-arg "HEIGHT=768" `
    --build-arg "WIDTH=1024" `
    .

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed!"
    exit $LASTEXITCODE
}

if ($DevMode) {
    Write-Host "✅ Development build completed successfully!"
    Write-Host "Image tagged as: $($IMAGE_TAG):latest"
    Write-Host "Use '.\run.ps1 dev' to start the development container"
} else {
    Write-Host "✅ Production build completed successfully!"
    Write-Host "Image tagged as: $($IMAGE_TAG):latest"
    Write-Host "Use '.\run.ps1' to start the production container"
}