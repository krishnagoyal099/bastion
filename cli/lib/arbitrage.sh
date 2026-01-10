#!/bin/bash
# Bastion TUI - Arbitrage Scanner
# Compare AMM vs Oracle prices

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ═══════════════════════════════════════════════════════════════════
# Simulated Oracle Prices
# ═══════════════════════════════════════════════════════════════════

get_oracle_prices() {
    python3 << 'EOF'
import json
import random
import time

random.seed(int(time.time()) // 5)

# Simulated oracle data (external exchange prices)
oracles = {
    "CSPR/USD": {
        "oracle": round(0.025 * (1 + random.uniform(-0.01, 0.02)), 6),
        "amm": round(0.025 * (1 + random.uniform(-0.02, 0.01)), 6)
    },
    "CSPR/BTC": {
        "oracle": round(0.0000003 * (1 + random.uniform(-0.01, 0.01)), 10),
        "amm": None  # Not available on our AMM
    },
    "CSPR/ETH": {
        "oracle": round(0.000008 * (1 + random.uniform(-0.01, 0.01)), 8),
        "amm": None
    }
}

print(json.dumps(oracles))
EOF
}

# ═══════════════════════════════════════════════════════════════════
# Scan for Opportunities
# ═══════════════════════════════════════════════════════════════════

scan_arbitrage() {
    local prices
    prices=$(get_oracle_prices)
    
    draw_section "Arbitrage Opportunities"
    
    echo -e "${C_DIM}Scanning for price discrepancies...${C_RESET}"
    echo ""
    
    # Animated scan
    for i in 1 2 3; do
        printf "\r  ${C_CYAN}⠋${C_RESET} Querying oracles%s" "$(printf '.%.0s' $(seq 1 $i))"
        sleep 0.3
    done
    printf "\r  ${C_SUCCESS}${ICON_SUCCESS}${C_RESET} Oracle data received     \n"
    
    sleep 0.2
    
    for i in 1 2 3; do
        printf "\r  ${C_CYAN}⠙${C_RESET} Checking AMM pools%s" "$(printf '.%.0s' $(seq 1 $i))"
        sleep 0.2
    done
    printf "\r  ${C_SUCCESS}${ICON_SUCCESS}${C_RESET} AMM prices fetched       \n"
    
    sleep 0.2
    
    printf "  ${C_CYAN}⠹${C_RESET} Calculating spreads..."
    sleep 0.3
    printf "\r  ${C_SUCCESS}${ICON_SUCCESS}${C_RESET} Analysis complete        \n"
    
    echo ""
    
    # Render table
    echo -e "${C_WHITE}"
    echo "┌─────────────────────────────────────────────────────────────────┐"
    echo "│                   ARBITRAGE OPPORTUNITIES                       │"
    echo "├───────────┬────────────┬────────────┬──────────┬───────────────┤"
    printf "│ %-9s │ %-10s │ %-10s │ %-8s │ %-13s │\n" "Pair" "AMM Price" "Oracle" "Spread" "PnL (1k CSPR)"
    echo "├───────────┼────────────┼────────────┼──────────┼───────────────┤"
    
    python3 << PYEOF
import json

prices_json = '''$prices'''
data = json.loads(prices_json)

for pair, info in data.items():
    oracle = info["oracle"]
    amm = info["amm"]
    
    if amm is None:
        print(f"│ {pair:<9} │ {'N/A':^10} │ \${oracle:<9} │ {'-':^8} │ {'-':^13} │")
    else:
        spread = (oracle - amm) / amm * 100
        pnl = 1000 * abs(oracle - amm)
        
        if spread > 0.5:
            arrow = "↑"
            color = "\033[38;5;114m"  # Green
        elif spread < -0.5:
            arrow = "↓"
            color = "\033[38;5;203m"  # Red
        else:
            arrow = "→"
            color = "\033[38;5;222m"  # Yellow
        
        spread_str = f"{arrow}{abs(spread):.2f}%"
        pnl_str = f"+\${pnl:.2f}" if pnl > 0.5 else "-"
        
        print(f"│ {pair:<9} │ \${amm:<9.6f} │ \${oracle:<9.6f} │ {color}{spread_str:^8}\033[0m │ {pnl_str:^13} │")
PYEOF
    
    echo "└───────────┴────────────┴────────────┴──────────┴───────────────┘"
    echo -e "${C_RESET}"
    
    echo ""
    echo -e "${C_DIM}Legend: ↑ AMM underpriced (buy opportunity) │ ↓ AMM overpriced (sell opportunity)${C_RESET}"
}

# ═══════════════════════════════════════════════════════════════════
# Arbitrage Menu
# ═══════════════════════════════════════════════════════════════════

arbitrage_menu() {
    while true; do
        clear_screen
        show_banner
        
        scan_arbitrage
        
        echo ""
        local choice
        choice=$(~/.local/bin/gum choose \
            "Refresh Scan" \
            "Execute Opportunity" \
            "← Back to Main Menu")
        
        case "$choice" in
            "Refresh Scan")
                continue
                ;;
            "Execute Opportunity")
                msg_info "Executing via Bastion Dark Pool to avoid MEV..."
                sleep 1
                # zkproof already sourced by main
                simulate_zk_proof "100" "BUY" >/dev/null
                msg_success "Order submitted with ZK protection!"
                sleep 2
                ;;
            "← Back to Main Menu"|"")
                break
                ;;
        esac
    done
}
