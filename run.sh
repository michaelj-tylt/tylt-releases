#!/bin/bash

set -e

# Load environment variables from .env.local
if [ -f ".env.local" ]; then
    export $(cat .env.local | xargs)
    echo "Loaded environment variables from .env.local"
else
    echo "Warning: .env.local file not found"
fi

# Set default MSASS if not specified
MSASS=${MSASS:-tester}
echo "Running microsass: $MSASS"

# Clear logs directory
rm -rf ./logs/*
mkdir -p ./logs

# Parse command line arguments
DEV_MODE=false
INTERACTIVE_MODE=true

for arg in "$@"; do
    case $arg in
        --dev|dev)
            DEV_MODE=true
            INTERACTIVE_MODE=false
            shift
            ;;
        --prod|prod)
            DEV_MODE=false
            INTERACTIVE_MODE=false
            shift
            ;;
        *)
            # Unknown argument
            ;;
    esac
done

# If no mode specified, prompt user
if [ "$INTERACTIVE_MODE" = "true" ]; then
    echo "Select mode for microsass: $MSASS"
    echo "1) Development mode (--dev)"
    echo "2) Production mode (--prod)"
    read -p "Enter your choice (1 or 2): " choice
    
    case $choice in
        1)
            DEV_MODE=true
            ;;
        2)
            DEV_MODE=false
            ;;
        *)
            echo "Invalid choice. Defaulting to production mode."
            DEV_MODE=false
            ;;
    esac
fi

# Load .env.local file if it exists
if [ -f ".env.local" ]; then
    echo "Loading environment variables from .env.local..."
    export $(grep -v '^#' .env.local | xargs)
fi

# Detect platform and determine which Docker image to use
PLATFORM=$(uname -s)
ARCH=$(uname -m)

if [ "$PLATFORM" = "Darwin" ]; then
    # Mac (Apple Silicon)
    if [ "$DEV_MODE" = "true" ]; then
        IMAGE_NAME="tylt-$MSASS-dev-arm64:latest"
        echo "Starting Tylt in development mode (Mac ARM64)..."
    else
        IMAGE_NAME="tylt-$MSASS-app-arm64:latest"
        echo "Starting Tylt in production mode (Mac ARM64)..."
    fi
else
    # Linux
    if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
        if [ "$DEV_MODE" = "true" ]; then
            IMAGE_NAME="tylt-$MSASS-dev-arm64:latest"
            echo "Starting Tylt in development mode (Linux ARM64)..."
        else
            IMAGE_NAME="tylt-$MSASS-app-arm64:latest"
            echo "Starting Tylt in production mode (Linux ARM64)..."
        fi
    else
        if [ "$DEV_MODE" = "true" ]; then
            IMAGE_NAME="tylt-$MSASS-dev-nix:latest"
            echo "Starting Tylt in development mode (Linux x86_64)..."
        else
            IMAGE_NAME="tylt-$MSASS-app-nix:latest"
            echo "Starting Tylt in production mode (Linux x86_64)..."
        fi
    fi
fi


# Set up Docker environment variables
DOCKER_ENV_VARS="-e DEV_MODE=$DEV_MODE"


# Check if image exists locally, if not pull from Docker Hub
if [ "$DEV_MODE" = "false" ]; then
    if ! docker images -q "$IMAGE_NAME" > /dev/null 2>&1; then
        echo "Production image not found. Pulling from Docker Hub..."
        docker pull "gotylt/$IMAGE_NAME" || {
            echo "❌ Pull failed! Please check your internet connection or build locally with: ./build/build.sh prod"
            exit 1
        }
        # Tag the pulled image with our local name
        docker tag "gotylt/$IMAGE_NAME" "$IMAGE_NAME"
    fi
fi

# Create db_data directory if it doesn't exist
mkdir -p ./db_data

# Create data directory for event store if it doesn't exist  
mkdir -p ./data


# Stop and remove any existing Tylt containers
echo "Stopping any existing Tylt containers..."
# Stop all containers from tylt images
docker ps -q --filter "ancestor=tylt-$MSASS-dev-nix" --filter "ancestor=tylt-$MSASS-app-nix" --filter "ancestor=tylt-$MSASS-dev-arm64" --filter "ancestor=tylt-$MSASS-app-arm64" | xargs -r docker stop
docker ps -aq --filter "ancestor=tylt-$MSASS-dev-nix" --filter "ancestor=tylt-$MSASS-app-nix" --filter "ancestor=tylt-$MSASS-dev-arm64" --filter "ancestor=tylt-$MSASS-app-arm64" | xargs -r docker rm
# Also clean up any containers that might be using our ports
docker ps -q | xargs -r -I {} sh -c 'docker port {} 2>/dev/null | grep -q ":3001\|:8000\|:5900\|:6080" && docker stop {} || true'

# Get absolute path for cross-platform compatibility
# Use realpath if available (Linux/WSL), otherwise use pwd (macOS/basic systems)
if command -v realpath > /dev/null 2>&1; then
    CURRENT_DIR="$(realpath .)"
else
    CURRENT_DIR="$(pwd)"
fi

docker run \
    $DOCKER_ENV_VARS \
    -v /etc/timezone:/etc/timezone:ro \
    -v /etc/localtime:/etc/localtime:ro \
    -e TZ=$(cat /etc/timezone 2>/dev/null || echo "UTC") \
    -v $HOME/.anthropic:/home/tylt/.anthropic \
    -v "${CURRENT_DIR}/user_data":/home/tylt/user_data \
    -v "${CURRENT_DIR}/user_data/.mozilla":/home/tylt/.mozilla \
    -v "${CURRENT_DIR}/user_data/.config/gtk-3.0":/home/tylt/.config/gtk-3.0 \
    -v "${CURRENT_DIR}/user_data/.config/gtk-2.0":/home/tylt/.config/gtk-2.0 \
    -v "${CURRENT_DIR}/user_data/.config/libreoffice":/home/tylt/.config/libreoffice \
    -v "${CURRENT_DIR}/user_data/.config/pulse":/home/tylt/.config/pulse \
    -v "${CURRENT_DIR}/user_data/.local":/home/tylt/.local \
    -v "${CURRENT_DIR}/user_data/.cache":/home/tylt/.cache \
    -v "${CURRENT_DIR}/user_data/Desktop":/home/tylt/Desktop \
    -v "${CURRENT_DIR}/user_data/Documents":/home/tylt/Documents \
    -v "${CURRENT_DIR}/user_data/Downloads":/home/tylt/Downloads \
    -v "${CURRENT_DIR}/logs":/home/tylt/logs \
    -v "${CURRENT_DIR}/db_data":/data/db \
    -v "${CURRENT_DIR}/data":/data \
    -v "${CURRENT_DIR}/image":/home/tylt/image \
    -p 5900:5900 \
    -p 3001:3001 \
    -p 6080:6080 \
    -p 8000:8000 \
    -p 27017:27017 \
    -p 27018:27018 \
    "$IMAGE_NAME"

echo ""
echo "Container stopped."