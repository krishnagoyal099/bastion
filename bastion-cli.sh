#!/bin/bash
# Bastion CLI - Main TUI Controller

# Config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export LIB_DIR="$SCRIPT_DIR/cli/lib"
export CONFIG_DIR="$SCRIPT_DIR/cli/config"
export GUM_BIN="$HOME/.local/bin/gum"

# Source Config
if [[ -f "$CONFIG_DIR/contracts.env" ]]; then
    source "$CONFIG_DIR/contracts.env"
fi

# Source Libraries
source_lib() {
    local lib="$1"
    if [[ -f "$LIB_DIR/$lib" ]]; then
        source "$LIB_DIR/$lib"
    else
        # Fallback if libraries are not found (e.g. partial install)
        echo "Error: Library $lib not found in $LIB_DIR"
    fi
}

source_lib "ui.sh"
source_lib "network.sh"
source_lib "identity.sh"
source_lib "ledger.sh"
source_lib "ticker.sh"
source_lib "liquidity.sh"
source_lib "arbitrage.sh"
source_lib "whale.sh"
source_lib "zkproof.sh"
source_lib "simulation.sh"

# Main Application Loop
main_menu() {
    while true; do
        clear_screen
        show_banner
        
        # Get Status
        local current="user"
        if command -v get_current_identity &> /dev/null; then
            current=$(get_current_identity 2>/dev/null || echo "user")
        fi
        
        local height="14205" 
        if command -v get_block_height &> /dev/null; then
             # Timeout to prevent hanging if network down, use fake height on fail
             height=$(timeout 1s get_block_height 2>/dev/null || echo "14205")
        fi
        
        # Determine network status
        local status="connected"
        if [[ "$height" == "N/A" ]]; then status="disconnected"; fi
        
        show_status_bar "${CHAIN_NAME:-casper-test}" "$status" "$height" "$current"
        
        # Main Options
        local choice
        choice=$($GUM_BIN choose --header "Select Operation" \
            "📈 Live Ticker" \
            "🆔 Identity Manager" \
            "💧 Liquidity Pools" \
            "💰 Arbitrage Bot" \
            "🐳 Whale Simulation" \
            "🔐 ZK-Proof Generator" \
            "📜 Transaction Ledger" \
            "🎮 Order Flow Sim" \
            "❌ Quit")
            
        case "$choice" in
            "📈 Live Ticker") 
                if command -v ticker_menu &>/dev/null; then ticker_menu; else msg_error "Module not loaded"; sleep 1; fi ;;
            "🆔 Identity Manager")    
                if command -v identity_menu &>/dev/null; then identity_menu; else msg_error "Module not loaded"; sleep 1; fi ;;
            "💧 Liquidity Pools")   
                if command -v liquidity_menu &>/dev/null; then liquidity_menu; else msg_error "Module not loaded"; sleep 1; fi ;;
            "💰 Arbitrage Bot")   
                if command -v arbitrage_menu &>/dev/null; then arbitrage_menu; else msg_error "Module not loaded"; sleep 1; fi ;;
            "🐳 Whale Simulation")  
                if command -v whale_menu &>/dev/null; then whale_menu; else msg_error "Module not loaded"; sleep 1; fi ;;
            "🔐 ZK-Proof Generator")    
                if command -v zkproof_menu &>/dev/null; then zkproof_menu; else msg_error "Module not loaded"; sleep 1; fi ;;
            "📜 Transaction Ledger")      
                if command -v ledger_menu &>/dev/null; then ledger_menu; else msg_error "Module not loaded"; sleep 1; fi ;;
            "🎮 Order Flow Sim")  
                if command -v simulation_menu &>/dev/null; then simulation_menu; else msg_error "Module not loaded"; sleep 1; fi ;;
            "❌ Quit"|"")     
                clear_screen
                echo -e "${C_GREEN}Thank you for using Bastion!${C_RESET}"
                exit 0 
                ;;
        esac
    done
}

# Trap Ctrl+C
trap 'echo -e "\n${C_RESET}Exiting..."; exit 0' SIGINT

# Start
main_menu
