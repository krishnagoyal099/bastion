#!/bin/bash
# Bastion TUI - Identity Manager
# Multi-wallet hot-swapping

# Config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Use persistent user directory for config, but keep keys in project for now
# based on user screenshot showing keys/ folder in project root
BASTION_HOME="$HOME/.bastion"
KEYS_DIR="$SCRIPT_DIR/../../keys"
CURRENT_IDENTITY_FILE="$BASTION_HOME/.current_identity"

# Ensure config directory exists
mkdir -p "$BASTION_HOME"
mkdir -p "$KEYS_DIR"

# ═══════════════════════════════════════════════════════════════════
# Identity Management
# ═══════════════════════════════════════════════════════════════════

# Available identities
# Available identities (defaults)
declare -A IDENTITIES=(
    ["user"]="user.pem:Primary trading account"
    ["whale"]="whale.pem:Large position account"
    ["attacker"]="attacker.pem:MEV simulation account"
)

PERSISTENT_IDENTITIES_FILE="$BASTION_HOME/.identities"

# Load persistent identities safely
if [[ -f "$PERSISTENT_IDENTITIES_FILE" ]]; then
    while IFS="=" read -r key value; do
        if [[ -n "$key" && -n "$value" ]]; then
            # Clean possible carriage returns or whitespace
            key=$(echo "$key" | tr -d '[:space:]')
            IDENTITIES["$key"]="$value"
        fi
    done < "$PERSISTENT_IDENTITIES_FILE"
fi

get_current_identity() {
    if [[ -f "$CURRENT_IDENTITY_FILE" ]]; then
        cat "$CURRENT_IDENTITY_FILE"
    else
        echo "user"
    fi
}

set_current_identity() {
    local identity="$1"
    mkdir -p "$(dirname "$CURRENT_IDENTITY_FILE")"
    echo "$identity" > "$CURRENT_IDENTITY_FILE"
}

get_identity_key_file() {
    local identity="${1:-$(get_current_identity)}"
    
    # lookup key filename from map
    local entry="${IDENTITIES[$identity]}"
    
    # If not found in map, check if file exists in KEYS_DIR
    if [[ -z "$entry" ]]; then
         if [[ -f "$KEYS_DIR/${identity}.pem" ]]; then
             echo "$KEYS_DIR/${identity}.pem"
         elif [[ -f "$KEYS_DIR/${identity}_secret_key.pem" ]]; then
             echo "$KEYS_DIR/${identity}_secret_key.pem"
         else
             # Fallback
             echo "$KEYS_DIR/${identity}.pem"
         fi
    else
         local key_file="${entry%%:*}"
         echo "$KEYS_DIR/$key_file"
    fi
}

get_identity_description() {
    local identity="$1"
    local desc="${IDENTITIES[$identity]#*:}"
    if [[ -z "$desc" || "$desc" == "$identity" ]]; then
        echo "Custom identity"
    else
        echo "$desc"
    fi
}

# ═══════════════════════════════════════════════════════════════════
# Key Generation Helper
# ═══════════════════════════════════════════════════════════════════

generate_identity_key() {
    local name="$1"
    local key_path="$KEYS_DIR/${name}.pem"
    local temp_dir="$KEYS_DIR/${name}_temp_dir"
    
    # Check if temp dir exists and remove it safely
    if [[ -d "$temp_dir" ]]; then rm -rf "$temp_dir"; fi
    
    casper-client keygen "$temp_dir" >/dev/null 2>&1
    
    if [[ -f "$temp_dir/secret_key.pem" ]]; then
        mv "$temp_dir/secret_key.pem" "$key_path"
        rm -rf "$temp_dir"
        return 0
    else
        # Fallback for older clients or different output behavior
        if [[ -f "${temp_dir}_secret_key.pem" ]]; then
             mv "${temp_dir}_secret_key.pem" "$key_path"
             rm -f "${temp_dir}_public_key.pem" "${temp_dir}_public_key_hex"
             return 0
        fi
    fi
    return 1
}

# ═══════════════════════════════════════════════════════════════════
# Identity Commands
# ═══════════════════════════════════════════════════════════════════

identity_list() {
    draw_section "Available Identities"
    
    local current=$(get_current_identity)
    
    # Header
    printf "${C_BOLD}${C_WHITE}  %-12s %-20s %-30s %s${C_RESET}\n" "Name" "Key File" "Description" "Status"
    echo "  ──────────────────────────────────────────────────────────────────────────"
    
    # Sort keys for consistent display
    local sorted_ids=($(printf '%s\n' "${!IDENTITIES[@]}" | sort))
    
    for identity in "${sorted_ids[@]}"; do
        local key_file="${IDENTITIES[$identity]%%:*}"
        local desc="${IDENTITIES[$identity]#*:}"
        local status=""
        local prefix="  "
        
        if [[ "$identity" == "$current" ]]; then
            status="${C_SUCCESS}● ACTIVE${C_RESET}"
            prefix="${C_SUCCESS}→ ${C_RESET}"
        else
            status="${C_DIM}○ inactive${C_RESET}"
        fi
        
        # Check if key file exists
        local key_path="$KEYS_DIR/$key_file"
        if [[ ! -f "$key_path" ]]; then
            status="${C_ERROR}✗ MISSING${C_RESET}"
        fi
        
        # Determine format string based on length to allow clean columns
        # Truncate description if too long
        if [[ ${#desc} -gt 30 ]]; then
            desc="${desc:0:27}..."
        fi
        
        printf "%b%-12s %-20s %-30s %b\n" "$prefix" "$identity" "$key_file" "$desc" "$status"
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
        
        if generate_identity_key "$target"; then
             msg_success "Generated new key: $key_file"
        else
             msg_error "Failed to generate key."
             return 1
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
                    # Ensure unique
                    if [[ -n "${IDENTITIES[$name]}" ]]; then
                        msg_error "Identity '$name' already exists!"
                        sleep 1
                        continue
                    fi

                    local key_path="$KEYS_DIR/${name}.pem"
                    msg_info "Generating key pair..."
                    
                    if generate_identity_key "$name"; then
                         # Add to array
                        IDENTITIES["$name"]="${name}.pem:Custom identity"
                        
                        # Persist
                        echo "$name=${name}.pem:Custom identity" >> "$PERSISTENT_IDENTITIES_FILE"
                        
                        msg_success "Created new identity: $name"
                        sleep 1
                    else
                         msg_error "Failed to generate key pair."
                         sleep 1
                    fi
                fi
                ;;
            "← Back to Main Menu"|"")
                break
                ;;
        esac
    done
}

# ═══════════════════════════════════════════════════════════════════
# Auto-Initialize Defaults
# ═══════════════════════════════════════════════════════════════════

ensure_default_identities() {
    # If the main 'user' key is missing, assume fresh install and generate defaults
    if [[ ! -f "$KEYS_DIR/user.pem" ]]; then
        echo -e "${C_DIM}Initializing default Bastion identities...${C_RESET}"
        mkdir -p "$KEYS_DIR"
        
        for id in "user" "whale" "attacker"; do
             if [[ ! -f "$KEYS_DIR/${id}.pem" ]]; then
                  echo -ne "  Creating ${C_CYAN}$id${C_RESET}..."
                  generate_identity_key "$id"
                  echo -e "${C_SUCCESS} Done${C_RESET}"
             fi
        done
        echo ""
    fi
}

ensure_default_identities
