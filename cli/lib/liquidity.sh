#!/bin/bash
# Bastion TUI - Liquidity Command Center
# Add/Remove liquidity with state diff preview

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ═══════════════════════════════════════════════════════════════════
# Pool Status
# ═══════════════════════════════════════════════════════════════════

show_pool_status() {
    draw_section "Current Pool Status"
    
    # Simulated pool data (would query contract in production)
    local reserve_a=125000
    local reserve_b=3125
    local total_lp=6250
    local user_lp=0
    
    echo ""
    printf "  %-20s %b%s%b\n" "Reserve A (CSPR):" "${C_CYAN}" "${reserve_a}" "${C_RESET}"
    printf "  %-20s %b%s%b\n" "Reserve B (mUSD):" "${C_CYAN}" "${reserve_b}" "${C_RESET}"
    printf "  %-20s %b%s%b\n" "Total LP Tokens:" "${C_PURPLE}" "${total_lp}" "${C_RESET}"
    printf "  %-20s %b%s%b\n" "Your LP Tokens:" "${C_PURPLE}" "${user_lp}" "${C_RESET}"
    printf "  %-20s %b%s%b\n" "Your Pool Share:" "${C_SUCCESS}" "0.00%" "${C_RESET}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════
# State Diff View
# ═══════════════════════════════════════════════════════════════════

show_state_diff() {
    local action="$1"
    local amount_a="$2"
    local amount_b="$3"
    
    # Current state (simulated)
    local curr_reserve_a=125000
    local curr_reserve_b=3125
    local curr_total_lp=6250
    local curr_user_lp=0
    
    # Calculate new state
    local new_reserve_a new_reserve_b new_total_lp new_user_lp new_share
    
    if [[ "$action" == "add" ]]; then
        new_reserve_a=$((curr_reserve_a + amount_a))
        new_reserve_b=$(python3 -c "print(round($curr_reserve_b + $amount_b, 2))")
        new_user_lp=$(python3 -c "print(int(($amount_a * $curr_total_lp) / $curr_reserve_a))")
        new_total_lp=$((curr_total_lp + new_user_lp))
        new_share=$(python3 -c "print(round($new_user_lp / $new_total_lp * 100, 2))")
    else
        new_user_lp=0
        new_total_lp=$curr_total_lp
        new_reserve_a=$curr_reserve_a
        new_reserve_b=$curr_reserve_b
        new_share=0
    fi
    
    draw_section "State Diff Preview"
    
    echo -e "${C_WHITE}"
    echo "┌─────────────────────────┬────────────────┬────────────────┬──────────┐"
    printf "│ %-23s │ %-14s │ %-14s │ %-8s │\n" "Property" "Current" "After" "Change"
    echo "├─────────────────────────┼────────────────┼────────────────┼──────────┤"
    
    # Reserve A
    local diff_a=$((new_reserve_a - curr_reserve_a))
    local diff_sign="+"
    [[ $diff_a -lt 0 ]] && diff_sign=""
    printf "│ %-23s │ %'14d │ ${C_CYAN}%'14d${C_WHITE} │ ${C_SUCCESS}%s%'d${C_WHITE} │\n" \
        "Reserve A (CSPR)" "$curr_reserve_a" "$new_reserve_a" "$diff_sign" "$diff_a"
    
    # Reserve B
    printf "│ %-23s │ %'14.2f │ ${C_CYAN}%'14.2f${C_WHITE} │ ${C_SUCCESS}+%.2f${C_WHITE} │\n" \
        "Reserve B (mUSD)" "$curr_reserve_b" "$new_reserve_b" "$amount_b"
    
    # LP Tokens
    printf "│ %-23s │ %'14d │ ${C_PURPLE}%'14d${C_WHITE} │ ${C_SUCCESS}+%d${C_WHITE} │\n" \
        "Your LP Tokens" "$curr_user_lp" "$new_user_lp" "$new_user_lp"
    
    # Pool Share
    printf "│ %-23s │ %13.2f%% │ ${C_SUCCESS}%13.2f%%${C_WHITE} │ ${C_SUCCESS}+%.2f%%${C_WHITE} │\n" \
        "Your Pool Share" "0.00" "$new_share" "$new_share"
    
    echo "└─────────────────────────┴────────────────┴────────────────┴──────────┘"
    echo -e "${C_RESET}"
}

# ═══════════════════════════════════════════════════════════════════
# Add Liquidity
# ═══════════════════════════════════════════════════════════════════

add_liquidity_ui() {
    clear_screen
    show_banner
    
    draw_section "Add Liquidity"
    
    show_pool_status
    
    echo -e "${C_DIM}Enter amounts to add to the pool:${C_RESET}"
    echo ""
    
    local amount_a
    amount_a=$(~/.local/bin/gum input --placeholder "Amount CSPR" --value "1000")
    
    # Calculate proportional amount B
    local ratio=$(python3 -c "print(round(3125 / 125000, 6))")
    local suggested_b=$(python3 -c "print(round($amount_a * $ratio, 2))")
    
    echo -e "${C_DIM}Suggested mUSD (to maintain ratio): $suggested_b${C_RESET}"
    
    local amount_b
    amount_b=$(~/.local/bin/gum input --placeholder "Amount mUSD" --value "$suggested_b")
    
    echo ""
    show_state_diff "add" "$amount_a" "$amount_b"
    
    ~/.local/bin/gum confirm "Confirm liquidity addition?" && {
        echo ""
        msg_info "Submitting add_liquidity transaction..."
        
        # Simulate transaction
        for i in 1 2 3; do
            printf "."
            sleep 0.5
        done
        
        local tx_hash="lp_$(openssl rand -hex 16)"
        msg_success "Liquidity added!"
        echo -e "  TX: ${C_DIM}$tx_hash${C_RESET}"
        
        # Log to ledger
        add_transaction "$tx_hash" "deposit" "$amount_a" "success" "$(get_current_identity)" '{"type":"add_liquidity"}'
    }
    
    echo ""
    ~/.local/bin/gum input --placeholder "Press Enter to continue..."
}

# ═══════════════════════════════════════════════════════════════════
# Remove Liquidity
# ═══════════════════════════════════════════════════════════════════

remove_liquidity_ui() {
    clear_screen
    show_banner
    
    draw_section "Remove Liquidity"
    
    show_pool_status
    
    msg_warn "You have 0 LP tokens. Nothing to remove."
    echo ""
    ~/.local/bin/gum input --placeholder "Press Enter to continue..."
}

# ═══════════════════════════════════════════════════════════════════
# Liquidity Menu
# ═══════════════════════════════════════════════════════════════════

liquidity_menu() {
    while true; do
        clear_screen
        show_banner
        
        local current=$(get_current_identity)
        show_status_bar "casper-test" "connected" "$(get_block_height)" "$current"
        
        draw_section "Liquidity Command Center"
        
        show_pool_status
        
        local choice
        choice=$(~/.local/bin/gum choose \
            "Add Liquidity" \
            "Remove Liquidity" \
            "View Pool Stats" \
            "← Back to Main Menu")
        
        case "$choice" in
            "Add Liquidity")
                add_liquidity_ui
                ;;
            "Remove Liquidity")
                remove_liquidity_ui
                ;;
            "View Pool Stats")
                show_pool_status
                ~/.local/bin/gum input --placeholder "Press Enter to continue..."
                ;;
            "← Back to Main Menu"|"")
                break
                ;;
        esac
    done
}
