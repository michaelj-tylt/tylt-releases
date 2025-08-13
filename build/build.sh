#!/bin/bash

set -e

# Change to parent directory so Docker context and paths are consistent
cd "$(dirname "$0")/.."

# Load environment variables from .env.local
if [ -f ".env.local" ]; then
    export $(cat .env.local | xargs)
    echo "Loaded environment variables from .env.local"
else
    echo "Warning: .env.local file not found"
fi

# Set default MSASS if not specified
MSASS=${MSASS:-tester}
echo "Building microsass: $MSASS"

# Function to show usage
show_usage() {
    echo "Usage: $0 [dev|prod]"
    echo ""
    echo "Build modes:"
    echo "  dev   - Development build (npm run dev, hot reload)"
    echo "  prod  - Production build (npm run build, optimized)"
    echo ""
    echo "Examples:"
    echo "  $0 dev    # Build for development"
    echo "  $0 prod   # Build for production"
    echo "  $0        # Interactive prompt"
}

# Parse command line arguments
MODE=""
if [ $# -eq 0 ]; then
    # Interactive mode - prompt user
    echo "=== Tylt Build System ==="
    echo "Choose build mode:"
    echo "  1) Development (hot reload, npm run dev)"
    echo "  2) Production (optimized, npm run build)"
    echo ""
    read -p "Enter choice [1-2]: " choice
    case $choice in
        1) MODE="dev" ;;
        2) MODE="prod" ;;
        *) echo "Invalid choice. Exiting."; exit 1 ;;
    esac
elif [ $# -eq 1 ]; then
    case $1 in
        dev|development) MODE="dev" ;;
        prod|production) MODE="prod" ;;
        -h|--help|help) show_usage; exit 0 ;;
        *) echo "Invalid mode: $1"; show_usage; exit 1 ;;
    esac
else
    echo "Too many arguments"
    show_usage
    exit 1
fi

# Detect platform and architecture
PLATFORM=$(uname -s)
ARCH=$(uname -m)

echo "=== Building Tylt ($MODE mode) ==="
echo "Detected platform: $PLATFORM"
echo "Detected architecture: $ARCH"

# Determine image tag and dockerfile based on platform/arch and mode
case "$PLATFORM" in
    "Linux")
        if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
            if [ "$MODE" = "dev" ]; then
                IMAGE_TAG="tylt-$MSASS-dev-arm64"
            else
                IMAGE_TAG="tylt-$MSASS-app-arm64"
            fi
            DOCKERFILE="Dockerfile.mac"
            PLATFORM_ARG="--platform linux/arm64"
            echo "Using ARM64 Linux build"
        else
            if [ "$MODE" = "dev" ]; then
                IMAGE_TAG="tylt-$MSASS-dev-nix"
            else
                IMAGE_TAG="tylt-$MSASS-app-nix"
            fi
            DOCKERFILE="Dockerfile.linux"
            PLATFORM_ARG=""
            echo "Using x86_64 Linux build"
        fi
        ;;
    "Darwin")
        if [ "$MODE" = "dev" ]; then
            IMAGE_TAG="tylt-$MSASS-dev-arm64"
        else
            IMAGE_TAG="tylt-$MSASS-app-arm64"
        fi
        DOCKERFILE="Dockerfile.mac"
        PLATFORM_ARG="--platform linux/arm64"
        echo "Using Mac ARM64 build (Apple Silicon)"
        ;;
    *)
        echo "❌ Unsupported platform: $PLATFORM"
        echo "This script supports Linux and macOS only."
        echo "For Windows, use build.bat $MODE"
        exit 1
        ;;
esac

if [ "$MODE" = "dev" ]; then
    echo "- Frontend will use 'npm run dev' for hot reloading"
    echo "- Python will run with live code reloading"
    echo "- Source code is already included in the image directory"
    
    # Install npm dependencies for development
    echo "Installing npm dependencies for development..."
    (cd image/$MSASS/frontend && npm install)
    
    # Database directory should be ready (separate for each MSASS)
    mkdir -p db_data_$MSASS
    
    DEV_MODE_ARG="true"
else
    echo "- Frontend will be pre-built with 'npm run build'"
    echo "- Python will run with optimized settings"
    
    # Ensure database directory exists for production (separate for each MSASS)
    if [ ! -d "db_data_$MSASS" ]; then
        mkdir -p db_data_$MSASS
        echo "Created database directory for $MSASS"
    fi
    
    # Build Next.js for production
    echo "Building Next.js for production..."
    (cd image/$MSASS/frontend && npm install --legacy-peer-deps && npm run build)
    
    DEV_MODE_ARG="false"
fi

# Build with BuildKit for better caching
echo "Building Docker image ($IMAGE_TAG)..."
DOCKER_BUILDKIT=1 docker build \
    $PLATFORM_ARG \
    --target app \
    --tag $IMAGE_TAG:latest \
    --file build/$DOCKERFILE \
    --build-arg DEV_MODE=$DEV_MODE_ARG \
    --build-arg MSASS=$MSASS \
    --build-arg DISPLAY_NUM=1 \
    --build-arg HEIGHT=768 \
    --build-arg WIDTH=1024 \
    .

echo "✅ $MODE build completed successfully!"
echo "Image tagged as: $IMAGE_TAG:latest"
if [ "$MODE" = "dev" ]; then
    echo "Use './run.sh dev' to start the development container"
else
    echo "Use './run.sh prod' to start the production container"
fi