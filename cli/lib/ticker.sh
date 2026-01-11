#!/bin/bash
# Bastion TUI - Live Market Ticker
# Non-flickering real-time display

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Cache for last known good values
LAST_PRICE_DATA=""

# ═══════════════════════════════════════════════════════════════════
# Real Price Data from Testnet
# ═══════════════════════════════════════════════════════════════════

get_price_data() {
    # Query real pool reserves from testnet AMM contract
    local reserves
    reserves=$(get_pool_reserves 2>/dev/null)
    
    # Check if we got real data or an error
    if [[ "$reserves" == "ERROR:"* || -z "$reserves" ]]; then
        # Contract unavailable - return error indicator
        echo '{"error": "Contract unavailable", "simulated": true, "price": 0.025, "change_pct": 0, "reserve_cspr": 0, "reserve_musd": 0, "volume_24h": 0, "lp_tokens": 0, "fee_pct": 0.3}'
        return 1
    fi
    
    # Parse reserves
    local reserve_cspr="${reserves%%:*}"
    local reserve_musd="${reserves##*:}"
    
    # Validate we got numbers
    if ! [[ "$reserve_cspr" =~ ^[0-9]+$ ]] || ! [[ "$reserve_musd" =~ ^[0-9.]+$ ]]; then
        echo '{"error": "Invalid reserve data", "simulated": true, "price": 0.025, "change_pct": 0, "reserve_cspr": 0, "reserve_musd": 0, "volume_24h": 0, "lp_tokens": 0, "fee_pct": 0.3}'
        return 1
    fi
    
    # Calculate price and other metrics
    python3 << PYEOF
import json

reserve_cspr = float('$reserve_cspr')
reserve_musd = float('$reserve_musd')

# Avoid division by zero
if reserve_cspr == 0:
    price = 0.025
else:
    price = reserve_musd / reserve_cspr

# Calculate LP tokens (sqrt of product)
lp_tokens = int((reserve_cspr * reserve_musd) ** 0.5) if reserve_cspr > 0 and reserve_musd > 0 else 0

# We don't have historical data on testnet, so change is 0
change_pct = 0.0

# Volume would require event indexing, set to unknown
volume = 0

print(json.dumps({
    "price": round(price, 6),
    "change_pct": round(change_pct, 2),
    "reserve_cspr": int(reserve_cspr),
    "reserve_musd": round(reserve_musd, 2),
    "volume_24h": volume,
    "lp_tokens": lp_tokens,
    "fee_pct": 0.3,
    "live": True
}))
PYEOF
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
    
    # Render Clean List (No Borders)
    echo -e "${C_WHITE}"
    printf "  ${C_BOLD}CSPR/mUSD${C_RESET}      ${C_CYAN}\$%.6f${C_WHITE}  ${change_color}%s %.2f%s${C_WHITE}\n" "$price" "$change_arrow" "$change" "%"
    echo "  ────────────────────────────────────────"
    printf "  Pool A:         ${C_CYAN}%-10s CSPR${C_WHITE} (\$%s)\n" "$(printf "%'d" $reserve_cspr)" "$(printf "%'d" ${depth_cspr%.*})"
    printf "  Pool B:         ${C_CYAN}%-10s mUSD${C_WHITE} (Vol: \$%s)\n" "$(printf "%'.2f" $reserve_musd)" "$(printf "%'d" $volume)"
    printf "  LP Tokens:      ${C_PURPLE}%-10s${C_WHITE}      (Fee: 0.3%%)\n" "$(printf "%'d" $lp_tokens)"
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
            local idx=3
        else
            # Ensure index is clamped between 0 and 7
            local idx=$(python3 -c "val = int(($price - $min) / ($max - $min) * 7); print(max(0, min(7, val)))")
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
        
        # Render Sparkline
        if (( ${#price_history[@]} >= 5 )); then
            render_sparkline "${price_history[@]}"
        else
             echo ""
        fi
        
        echo -e "${C_DIM}Last update: $(date '+%H:%M:%S') │ Updates every 2s${C_RESET}"
        
        # Clear any remaining artifacts below this point
        tput ed
        
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
    
    
    run_ticker
}
