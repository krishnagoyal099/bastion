#!/bin/bash
# Bastion TUI - Identity Manager
# Multi-wallet hot-swapping

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

KEYS_DIR="$SCRIPT_DIR/../../keys"
CURRENT_IDENTITY_FILE="$KEYS_DIR/.current_identity"

# ═══════════════════════════════════════════════════════════════════
# Identity Management
# ═══════════════════════════════════════════════════════════════════

# Available identities
declare -A IDENTITIES=(
    ["user"]="user.pem:Primary trading account"
    ["whale"]="whale.pem:Large position account"
    ["attacker"]="attacker.pem:MEV simulation account"
)

get_current_identity() {
    if [[ -f "$CURRENT_IDENTITY_FILE" ]]; then
        cat "$CURRENT_IDENTITY_FILE"
    else
        echo "user"
    fi
}

set_current_identity() {
    local identity="$1"
    echo "$identity" > "$CURRENT_IDENTITY_FILE"
}

get_identity_key_file() {
    local identity="${1:-$(get_current_identity)}"
    local key_file="${IDENTITIES[$identity]%%:*}"
    echo "$KEYS_DIR/$key_file"
}

get_identity_description() {
    local identity="$1"
    echo "${IDENTITIES[$identity]#*:}"
}

# ═══════════════════════════════════════════════════════════════════
# Identity Commands
# ═══════════════════════════════════════════════════════════════════

identity_list() {
    draw_section "Available Identities"
    
    local current=$(get_current_identity)
    
    printf "${C_BOLD}${C_WHITE}%-12s %-20s %-35s %s${C_RESET}\n" "Name" "Key File" "Description" "Status"
    echo "────────────────────────────────────────────────────────────────────────────"
    
    for identity in "${!IDENTITIES[@]}"; do
        local key_file="${IDENTITIES[$identity]%%:*}"
        local desc="${IDENTITIES[$identity]#*:}"
        local status=""
        local icon=""
        
        if [[ "$identity" == "$current" ]]; then
            status="${C_SUCCESS}● ACTIVE${C_RESET}"
            icon="${C_SUCCESS}→${C_RESET}"
        else
            status="${C_DIM}○ inactive${C_RESET}"
            icon=" "
        fi
        
        # Check if key file exists
        local key_path="$KEYS_DIR/$key_file"
        local key_status
        if [[ -f "$key_path" ]]; then
            key_status="${C_SUCCESS}✓${C_RESET}"
        else
            key_status="${C_ERROR}✗ missing${C_RESET}"
        fi
        
        printf "%s %-12s %-20s %-35s %b\n" "$icon" "$identity" "$key_file" "$desc" "$status"
    done
    echo ""
}

identity_switch() {
    local target="$1"
    
    if [[ -z "$target" ]]; then
        # Interactive selection with gum
        msg_info "Select identity to activate:"
        
        local options=()
        for identity in "${!IDENTITIES[@]}"; do
            local desc="${IDENTITIES[$identity]#*:}"
            options+=("$identity|$desc")
        done
        
        target=$(printf '%s\n' "${options[@]}" | ~/.local/bin/gum choose --header "Switch Identity" | cut -d'|' -f1)
    fi
    
    if [[ -z "${IDENTITIES[$target]}" ]]; then
        msg_error "Unknown identity: $target"
        return 1
    fi
    
    local key_file=$(get_identity_key_file "$target")
    if [[ ! -f "$key_file" ]]; then
        msg_error "Key file not found: $key_file"
        msg_info "Creating placeholder key..."
        mkdir -p "$KEYS_DIR"
        # Generate a new key for demo purposes
        casper-client keygen "$KEYS_DIR/${target}_temp" 2>/dev/null || true
        if [[ -f "$KEYS_DIR/${target}_temp_secret_key.pem" ]]; then
            mv "$KEYS_DIR/${target}_temp_secret_key.pem" "$key_file"
            rm -f "$KEYS_DIR/${target}_temp_public_key.pem" "$KEYS_DIR/${target}_temp_public_key_hex"
            msg_success "Generated new key: $key_file"
        fi
    fi
    
    set_current_identity "$target"
    msg_success "Switched to identity: ${C_BOLD}$target${C_RESET}"
    
    # Show balance
    local balance=$(get_identity_balance "$target")
    echo -e "  Balance: ${C_CYAN}$balance CSPR${C_RESET}"
}

identity_info() {
    local identity=$(get_current_identity)
    local key_file=$(get_identity_key_file "$identity")
    local desc=$(get_identity_description "$identity")
    
    draw_section "Current Identity"
    
    echo -e "  ${C_BOLD}Identity:${C_RESET}    $identity"
    echo -e "  ${C_BOLD}Description:${C_RESET} $desc"
    echo -e "  ${C_BOLD}Key File:${C_RESET}    $key_file"
    
    if [[ -f "$key_file" ]]; then
        local public_key
        public_key=$(casper-client account-address --public-key "$key_file" 2>/dev/null | grep -oP '^[a-f0-9]+' | head -1)
        echo -e "  ${C_BOLD}Public Key:${C_RESET}  ${public_key:0:20}..."
        
        # Try to get balance
        local balance=$(get_identity_balance "$identity")
        echo -e "  ${C_BOLD}Balance:${C_RESET}     ${C_CYAN}$balance CSPR${C_RESET}"
    else
        echo -e "  ${C_ERROR}Key file not found!${C_RESET}"
    fi
    echo ""
}

get_identity_balance() {
    local identity="$1"
    local key_file=$(get_identity_key_file "$identity")
    
    if [[ ! -f "$key_file" ]]; then
        echo "0.00"
        return
    fi
    
    # Get account hash and balance
    local account_hash
    account_hash=$(get_account_hash "$key_file" 2>/dev/null)
    
    if [[ -n "$account_hash" ]]; then
        get_balance "$account_hash"
    else
        echo "0.00"
    fi
}

# ═══════════════════════════════════════════════════════════════════
# Identity Menu
# ═══════════════════════════════════════════════════════════════════
identity_menu() {
    while true; do
        clear_screen
        show_banner
        
        local current=$(get_current_identity)
        show_status_bar "casper-test" "connected" "$(get_block_height)" "$current"
        
        identity_list
        
        local choice
        choice=$(~/.local/bin/gum choose \
            "Switch Identity" \
            "View Current" \
            "Generate New Key" \
            "← Back to Main Menu")
        
        case "$choice" in
            "Switch Identity")
                identity_switch
                sleep 1
                ;;
            "View Current")
                identity_info
                ~/.local/bin/gum input --placeholder "Press Enter to continue..."
                ;;
            "Generate New Key")
                local name
                name=$(~/.local/bin/gum input --placeholder "Enter identity name (e.g., trader1)")
                if [[ -n "$name" ]]; then
                    local key_path="$KEYS_DIR/${name}.pem"
                    casper-client keygen "$KEYS_DIR/${name}_temp" 2>/dev/null
                    mv "$KEYS_DIR/${name}_temp_secret_key.pem" "$key_path" 2>/dev/null
                    rm -f "$KEYS_DIR/${name}_temp"* 2>/dev/null
                    IDENTITIES["$name"]="${name}.pem:Custom identity"
                    msg_success "Created new identity: $name"
                    sleep 1
                fi
                ;;
            "← Back to Main Menu"|"")
                break
                ;;
        esac
    done
}
