#!/bin/bash
# Bastion TUI - Live Market Ticker
# Non-flickering real-time display

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ═══════════════════════════════════════════════════════════════════
# Simulated Price Data
# ═══════════════════════════════════════════════════════════════════

get_price_data() {
    # In production, this would query real AMM reserves
    # For demo, we'll simulate realistic price movements
    
    python3 << 'EOF'
import random
import json
import time

# Seed with time for reproducible but varying prices
random.seed(int(time.time()) // 2)  # Changes every 2 seconds

# Base values
base_price = 0.025
base_reserve_cspr = 125000
base_reserve_musd = 3125
base_volume = 1200

# Add some randomness
price = base_price * (1 + random.uniform(-0.02, 0.02))
reserve_cspr = int(base_reserve_cspr * (1 + random.uniform(-0.05, 0.05)))
reserve_musd = round(base_reserve_musd * (1 + random.uniform(-0.05, 0.05)), 2)
volume = int(base_volume * (1 + random.uniform(-0.3, 0.5)))

# Calculate 24h change
change_pct = random.uniform(-3, 5)

print(json.dumps({
    "price": round(price, 6),
    "change_pct": round(change_pct, 2),
    "reserve_cspr": reserve_cspr,
    "reserve_musd": reserve_musd,
    "volume_24h": volume,
    "lp_tokens": int((reserve_cspr * reserve_musd) ** 0.5),
    "fee_pct": 0.3
}))
EOF
}

# ═══════════════════════════════════════════════════════════════════
# Render Ticker Display
# ═══════════════════════════════════════════════════════════════════

render_ticker() {
    local data="$1"
    
    local price=$(echo "$data" | python3 -c "import sys,json; print(json.load(sys.stdin)['price'])")
    local change=$(echo "$data" | python3 -c "import sys,json; print(json.load(sys.stdin)['change_pct'])")
    local reserve_cspr=$(echo "$data" | python3 -c "import sys,json; print(json.load(sys.stdin)['reserve_cspr'])")
    local reserve_musd=$(echo "$data" | python3 -c "import sys,json; print(json.load(sys.stdin)['reserve_musd'])")
    local volume=$(echo "$data" | python3 -c "import sys,json; print(json.load(sys.stdin)['volume_24h'])")
    local lp_tokens=$(echo "$data" | python3 -c "import sys,json; print(json.load(sys.stdin)['lp_tokens'])")
    
    # Determine change color
    local change_color="$C_SUCCESS"
    local change_arrow="↑"
    if (( $(echo "$change < 0" | bc -l) )); then
        change_color="$C_ERROR"
        change_arrow="↓"
    fi
    
    # Calculate depths
    local depth_cspr=$(python3 -c "print(round($reserve_cspr * $price, 2))")
    
    # Render box with strict padding
    # Total inner width: 62 chars
    echo -e "${C_WHITE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    printf "║  ${C_BOLD}CSPR/mUSD${C_RESET}${C_WHITE} │ Price: ${C_CYAN}\$%-8.6f${C_WHITE} │ ${change_color}%s %-6.2f%%${C_WHITE}           ║\n" "$price" "$change_arrow" "$change"
    echo "╠══════════════════════════════════════════════════════════════╣"
    printf "║  Pool A: ${C_CYAN}%-12s CSPR${C_WHITE} │ Depth: \$%-13s       ║\n" "$(printf "%'d" $reserve_cspr)" "$(printf "%'d" ${depth_cspr%.*})"
    printf "║  Pool B: ${C_CYAN}%-12s mUSD${C_WHITE} │ Volume 24h: \$%-8s       ║\n" "$(printf "%'.2f" $reserve_musd)" "$(printf "%'d" $volume)"
    printf "║  LP Tokens: ${C_PURPLE}%-12s${C_WHITE}      │ Fee: 0.3%%                 ║\n" "$(printf "%'d" $lp_tokens)"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${C_RESET}"
}

# ═══════════════════════════════════════════════════════════════════
# Mini Sparkline Chart
# ═══════════════════════════════════════════════════════════════════

render_sparkline() {
    local -a prices=("$@")
    local chars=(" " "▂" "▃" "▄" "▅" "▆" "▇" "█")
    
    # Find min/max
    local min max
    min=$(printf '%s\n' "${prices[@]}" | sort -n | head -1)
    max=$(printf '%s\n' "${prices[@]}" | sort -n | tail -1)
    
    echo -ne "  ${C_DIM}Price 1h:${C_RESET} ${C_CYAN}"
    
    for price in "${prices[@]}"; do
        if (( $(echo "$max == $min" | bc -l) )); then
            local idx=4
        else
            local idx=$(python3 -c "print(int(($price - $min) / ($max - $min) * 7))")
        fi
        echo -n "${chars[$idx]}"
    done
    
    echo -e "${C_RESET}"
}

# ═══════════════════════════════════════════════════════════════════
# Live Ticker Loop
# ═══════════════════════════════════════════════════════════════════

run_ticker() {
    hide_cursor
    trap "show_cursor; return" INT TERM
    
    local price_history=()
    
    echo -e "${C_DIM}Press Ctrl+C to return to menu${C_RESET}"
    echo ""
    
    # Reserve space for the widget (9 lines)
    for i in {1..9}; do echo ""; done
    
    # Save cursor position at start of widget area
    tput sc
    
    while true; do
        # Restore cursor to top of widget area
        tput rc
        
        # Get current data
        local data
        data=$(get_price_data)
        
        # Extract price for history
        local current_price
        current_price=$(echo "$data" | python3 -c "import sys,json; print(json.load(sys.stdin)['price'])")
        
        # Add to history (keep last 20)
        price_history+=("$current_price")
        if (( ${#price_history[@]} > 20 )); then
            price_history=("${price_history[@]:1}")
        fi
        
        # Render Frame
        render_ticker "$data"
        echo ""
        
        # Render Sparkline
        if (( ${#price_history[@]} >= 5 )); then
            render_sparkline "${price_history[@]}"
        else
            echo "" 
        fi
        
        echo ""
        echo -e "${C_DIM}Last update: $(date '+%H:%M:%S') │ Updates every 2s${C_RESET}"
        
        sleep 2
    done
}

# ═══════════════════════════════════════════════════════════════════
# Ticker Entry Point
# ═══════════════════════════════════════════════════════════════════

ticker_menu() {
    clear_screen
    show_banner
    
    draw_section "Live Market Ticker"
    
    # Prime the display
    echo ""
    echo ""
    echo ""
    echo ""
    echo ""
    echo ""
    echo ""
    echo ""
    
    run_ticker
}
