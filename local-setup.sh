#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║   ₿  OpenClaw + aibtc Local Setup                         ║"
echo "║                                                           ║"
echo "║   Bitcoin & Stacks blockchain agent (Docker Desktop)      ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check for Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed.${NC}"
    echo "Please install Docker Desktop: https://docs.docker.com/get-docker/"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo -e "${RED}Error: Docker is not running.${NC}"
    echo "Please start Docker Desktop."
    exit 1
fi

echo -e "${GREEN}✓ Docker is installed and running${NC}"

# Check for docker compose
if ! docker compose version &> /dev/null; then
    echo -e "${RED}Error: Docker Compose is not available.${NC}"
    echo "Please update Docker Desktop or install Docker Compose."
    exit 1
fi

echo -e "${GREEN}✓ Docker Compose is available${NC}"

# Check for git
if ! command -v git &> /dev/null; then
    echo -e "${RED}Error: git is not installed.${NC}"
    echo "Please install git: https://git-scm.com/downloads"
    exit 1
fi

echo -e "${GREEN}✓ Git is available${NC}"
echo ""

# Install directory
INSTALL_DIR="$HOME/openclaw-aibtc"

# Clone or update repo
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}Found existing installation at $INSTALL_DIR${NC}"
    read -p "Update existing installation? (y/N): " UPDATE
    if [[ "$UPDATE" =~ ^[Yy]$ ]]; then
        cd "$INSTALL_DIR"
        git pull
    fi
else
    echo -e "${BLUE}Cloning repository...${NC}"
    git clone https://github.com/biwasxyz/openclaw-aibtc.git "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"

# Run the main setup script
echo -e "${BLUE}Running setup...${NC}"
./setup.sh

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Local Setup Complete!                                   ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Installation directory: ${YELLOW}$INSTALL_DIR${NC}"
echo ""
echo -e "${BLUE}Useful commands:${NC}"
echo "  cd $INSTALL_DIR"
echo "  docker compose logs -f     # View logs"
echo "  docker compose restart     # Restart"
echo "  docker compose down        # Stop"
echo ""
