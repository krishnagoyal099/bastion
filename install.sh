#!/bin/bash
#
# Bastion CLI Installer
# Privacy-preserving dark pool trading on Casper Network
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/krishnagoyal099/bastion/main/install.sh | bash
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

INSTALL_DIR="$HOME/.bastion"
BIN_DIR="$HOME/.local/bin"
REPO_URL="https://github.com/krishnagoyal099/bastion"
RAW_URL="https://raw.githubusercontent.com/krishnagoyal099/bastion/main"

print_banner() {
    echo -e "${BLUE}"
    cat << 'EOF'
    ____            __  _           
   / __ )____ _____/ /_(_)___  ____ 
  / /_/ / __ `/ __/ __/ / __ \/ __ \
 / /_/ / /_/ (__  ) /_/ / /_/ / / / /
/_____/\__,_/____/\__/_/\____/_/ /_/ 
                                     
    Dark Pool Trading on Casper
EOF
    echo -e "${NC}"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

detect_os() {
    OS="$(uname -s)"
    ARCH="$(uname -m)"
    
    case "$OS" in
        Linux*)     OS_TYPE="linux";;
        Darwin*)    OS_TYPE="macos";;
        *)          log_error "Unsupported operating system: $OS. Bastion only supports Linux and macOS.";;
    esac
    
    log_info "Detected OS: $OS_TYPE ($ARCH)"
}

check_dependencies() {
    log_info "Checking dependencies..."
    
    local missing=()
    
    # Required
    command -v curl >/dev/null 2>&1 || missing+=("curl")
    command -v git >/dev/null 2>&1 || missing+=("git")
    command -v jq >/dev/null 2>&1 || missing+=("jq")
    
    # Check for gum
    if ! command -v gum >/dev/null 2>&1; then
        log_warn "gum is not installed. Installing..."
        install_gum
    else
        log_success "gum is installed"
    fi
    
    if [ ${#missing[@]} -ne 0 ]; then
        log_error "Missing required dependencies: ${missing[*]}\nPlease install them and try again."
    fi
    
    log_success "All dependencies satisfied"
}

install_gum() {
    if [ "$OS_TYPE" = "macos" ]; then
        if command -v brew >/dev/null 2>&1; then
            brew install gum
        else
            log_error "Homebrew is required to install gum on macOS. Install from https://brew.sh"
        fi
    elif [ "$OS_TYPE" = "linux" ]; then
        # Try different package managers
        if command -v apt-get >/dev/null 2>&1; then
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
            echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
            sudo apt update && sudo apt install -y gum
        elif command -v dnf >/dev/null 2>&1; then
            echo '[charm]
name=Charm
baseurl=https://repo.charm.sh/yum/
enabled=1
gpgcheck=1
gpgkey=https://repo.charm.sh/yum/gpg.key' | sudo tee /etc/yum.repos.d/charm.repo
            sudo dnf install -y gum
        elif command -v pacman >/dev/null 2>&1; then
            sudo pacman -S gum
        else
            log_warn "Could not auto-install gum. Please install manually: https://github.com/charmbracelet/gum"
        fi
    fi
}

create_directories() {
    log_info "Creating installation directories..."
    
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$INSTALL_DIR/cli/lib"
    mkdir -p "$INSTALL_DIR/cli/config"
    mkdir -p "$INSTALL_DIR/keys"
    mkdir -p "$BIN_DIR"
    
    log_success "Directories created"
}

download_files() {
    log_info "Downloading Bastion CLI..."
    
    # Download main CLI
    curl -fsSL "$RAW_URL/bastion-cli.sh" -o "$INSTALL_DIR/bastion-cli.sh"
    chmod +x "$INSTALL_DIR/bastion-cli.sh"
    
    # Download CLI modules
    local modules=("ui" "identity" "network" "ledger" "simulation" "ticker" "liquidity" "arbitrage" "whale" "zkproof")
    
    for module in "${modules[@]}"; do
        curl -fsSL "$RAW_URL/cli/lib/${module}.sh" -o "$INSTALL_DIR/cli/lib/${module}.sh"
        chmod +x "$INSTALL_DIR/cli/lib/${module}.sh"
    done
    
    # Download config
    curl -fsSL "$RAW_URL/cli/config/contracts.env" -o "$INSTALL_DIR/cli/config/contracts.env" 2>/dev/null || true
    
    log_success "Downloaded all CLI components"
}

create_launcher() {
    log_info "Creating launcher script..."
    
    cat > "$BIN_DIR/bastion" << 'LAUNCHER'
#!/bin/bash
BASTION_HOME="$HOME/.bastion"
exec "$BASTION_HOME/bastion-cli.sh" "$@"
LAUNCHER
    
    chmod +x "$BIN_DIR/bastion"
    
    log_success "Launcher created at $BIN_DIR/bastion"
}

update_path() {
    local shell_rc=""
    
    if [ -n "$ZSH_VERSION" ] || [ -f "$HOME/.zshrc" ]; then
        shell_rc="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ] || [ -f "$HOME/.bashrc" ]; then
        shell_rc="$HOME/.bashrc"
    fi
    
    if [ -n "$shell_rc" ]; then
        if ! grep -q "$BIN_DIR" "$shell_rc" 2>/dev/null; then
            echo "" >> "$shell_rc"
            echo "# Bastion CLI" >> "$shell_rc"
            echo "export PATH=\"\$PATH:$BIN_DIR\"" >> "$shell_rc"
            log_info "Added $BIN_DIR to PATH in $shell_rc"
        fi
    fi
    
    export PATH="$PATH:$BIN_DIR"
}

print_success() {
    echo ""
    echo -e "${GREEN}Bastion CLI installed successfully!${NC}"
    echo ""
    echo "To get started:"
    echo ""
    echo -e "  ${YELLOW}1.${NC} Restart your terminal or run:"
    echo -e "     ${BLUE}source ~/.bashrc${NC}  (or ~/.zshrc for zsh)"
    echo ""
    echo -e "  ${YELLOW}2.${NC} Launch Bastion:"
    echo -e "     ${BLUE}bastion${NC}"
    echo ""
    echo -e "Installation directory: ${BLUE}$INSTALL_DIR${NC}"
    echo ""
}

uninstall() {
    log_info "Uninstalling Bastion..."
    rm -rf "$INSTALL_DIR"
    rm -f "$BIN_DIR/bastion"
    log_success "Bastion has been uninstalled"
    exit 0
}

main() {
    print_banner
    
    # Check for uninstall flag
    if [ "$1" = "--uninstall" ] || [ "$1" = "-u" ]; then
        uninstall
    fi
    
    detect_os
    check_dependencies
    create_directories
    download_files
    create_launcher
    update_path
    print_success
}

main "$@"
