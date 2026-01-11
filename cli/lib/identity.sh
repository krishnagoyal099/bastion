#!/bin/bash
# Bastion TUI - Identity Manager
# Multi-wallet hot-swapping

# Config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Use persistent user directory for config, but keep keys in project for now
# based on user screenshot showing keys/ folder in project root
BASTION_HOME="$HOME/.bastion"
KEYS_DIR="$SCRIPT_DIR/../../keys"
SUPER_KEYS_FILE="$KEYS_DIR/super.keys"
CURRENT_IDENTITY_FILE="$BASTION_HOME/.current_identity"

# Ensure config directory exists
mkdir -p "$BASTION_HOME"
mkdir -p "$KEYS_DIR"

# ═══════════════════════════════════════════════════════════════════
# Super Keys (Master Wallet) Loader
# ═══════════════════════════════════════════════════════════════════
SUPER_PUBLIC_KEY=""
SUPER_PRIVATE_KEY_PEM=""

load_super_keys() {
    if [[ -f "$SUPER_KEYS_FILE" ]]; then
        # Source the super.keys file to get PUBLIC_KEY and PRIVATE_KEY_PEM
        source "$SUPER_KEYS_FILE"
        SUPER_PUBLIC_KEY="$PUBLIC_KEY"
        SUPER_PRIVATE_KEY_PEM="$PRIVATE_KEY_PEM"
        
        # Create user.pem from PRIVATE_KEY_PEM if it doesn't match
        if [[ -n "$SUPER_PRIVATE_KEY_PEM" ]]; then
            echo -e "$SUPER_PRIVATE_KEY_PEM" > "$KEYS_DIR/user.pem"
        fi
        
        return 0
    fi
    return 1
}

# Try to load super.keys on identity.sh load
load_super_keys

# ═══════════════════════════════════════════════════════════════════
# Identity Management
# ═══════════════════════════════════════════════════════════════════

# Available identities
# Ensure clean associative array
unset IDENTITIES
declare -A IDENTITIES

PERSISTENT_IDENTITIES_FILE="$BASTION_HOME/.identities"

# Auto-discover .pem files in keys directory
discover_identities() {
    # Scan keys directory for .pem files
    if [[ -d "$KEYS_DIR" ]]; then
        for pem_file in "$KEYS_DIR"/*.pem; do
            if [[ -f "$pem_file" ]]; then
                local basename=$(basename "$pem_file")
                local name="${basename%.pem}"
                
                # Skip if already exists
                if [[ -z "${IDENTITIES[$name]}" ]]; then
                    # Determine description based on name
                    local desc="Discovered key"
                    case "$name" in
                        user) desc="Primary trading account" ;;
                        whale) desc="Large position account" ;;
                        attacker) desc="MEV simulation account" ;;
                        *) desc="Custom identity" ;;
                    esac
                    IDENTITIES["$name"]="$basename:$desc"
                fi
            fi
        done
    fi
}

# Load persistent identities from file (overrides discovered)
load_persistent_identities() {
    if [[ -f "$PERSISTENT_IDENTITIES_FILE" ]]; then
        while IFS="=" read -r key value; do
            if [[ -n "$key" && -n "$value" ]]; then
                key=$(echo "$key" | tr -d '[:space:]')
                IDENTITIES["$key"]="$value"
            fi
        done < "$PERSISTENT_IDENTITIES_FILE"
    fi
}

# Initialize: First discover, then load persistent (to allow overrides)
discover_identities
load_persistent_identities

# Sanity check: Remove invalid [0] key if present
if [[ -n "${IDENTITIES[0]}" ]]; then
    unset "IDENTITIES[0]"
fi

get_current_identity() {
    local current="user"
    if [[ -f "$CURRENT_IDENTITY_FILE" ]]; then
        current=$(cat "$CURRENT_IDENTITY_FILE")
    fi
    
    # If current stored identity is invalid (e.g. "0"), revert to user
    if [[ "$current" == "0" ]]; then
        current="user"
    fi
    echo "$current"
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
    # Re-discover identities in case they weren't loaded
    if [[ ${#IDENTITIES[@]} -eq 0 ]]; then
        discover_identities
        load_persistent_identities
    fi
    
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
    
    # Re-discover identities in case they weren't loaded
    if [[ ${#IDENTITIES[@]} -eq 0 ]]; then
        discover_identities
        load_persistent_identities
    fi
    
    if [[ -z "$target" ]]; then
        # Check if there are any identities to choose from
        if [[ ${#IDENTITIES[@]} -eq 0 ]]; then
            msg_error "No identities found. Create a key first."
            return 1
        fi
        
        # Interactive selection with gum
        msg_info "Select identity to activate:"
        
        local options=()
        for identity in "${!IDENTITIES[@]}"; do
            local desc="${IDENTITIES[$identity]#*:}"
            options+=("$identity|$desc")
        done
        
        if [[ ${#options[@]} -eq 0 ]]; then
            msg_error "No identities available"
            return 1
        fi
        
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
    
    # If this is 'user' identity and we have super.keys loaded, use the public key directly
    if [[ "$identity" == "user" && -n "$SUPER_PUBLIC_KEY" ]]; then
        # Use REST API with public key
        if command -v get_account_balance_rest &>/dev/null; then
            get_account_balance_rest "$SUPER_PUBLIC_KEY"
            return
        fi
    fi
    
    # Get key file for identity
    local key_file=$(get_identity_key_file "$identity")
    
    if [[ ! -f "$key_file" ]]; then
        echo "0.00"
        return
    fi
    
    # Try to extract public key from PEM file
    local public_key
    public_key=$(casper-client account-address --public-key "$key_file" 2>/dev/null | grep -oE '^[a-f0-9]+' | head -1)
    
    if [[ -n "$public_key" ]]; then
        # Use REST API if available
        if command -v get_account_balance_rest &>/dev/null; then
            get_account_balance_rest "$public_key"
        else
            # Fallback to RPC
            local account_hash
            account_hash=$(get_account_hash "$key_file" 2>/dev/null)
            if [[ -n "$account_hash" ]]; then
                get_balance "$account_hash"
            else
                echo "0.00"
            fi
        fi
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
# First-Time Setup
# ═══════════════════════════════════════════════════════════════════

import_secret_key() {
    local name="$1"
    local source_path="$2"
    local target_path="$KEYS_DIR/${name}.pem"
    
    # Validate source file exists
    if [[ ! -f "$source_path" ]]; then
        msg_error "File not found: $source_path"
        return 1
    fi
    
    # Validate it looks like a PEM file
    if ! head -1 "$source_path" | grep -qE "^-----BEGIN"; then
        msg_error "File does not appear to be a valid PEM key file"
        return 1
    fi
    
    # Copy to keys directory
    cp "$source_path" "$target_path"
    
    if [[ -f "$target_path" ]]; then
        msg_success "Imported key as: $name"
        return 0
    else
        msg_error "Failed to import key"
        return 1
    fi
}

first_time_setup() {
    echo ""
    echo -e "${C_BOLD}${C_WHITE}╔════════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_BOLD}${C_WHITE}║               WELCOME TO BASTION                               ║${C_RESET}"
    echo -e "${C_BOLD}${C_WHITE}║                                                                ║${C_RESET}"
    echo -e "${C_BOLD}${C_WHITE}║  No wallet keys detected. Let's set up your first identity.   ║${C_RESET}"
    echo -e "${C_BOLD}${C_WHITE}╚════════════════════════════════════════════════════════════════╝${C_RESET}"
    echo ""
    
    local setup_choice
    setup_choice=$(~/.local/bin/gum choose \
        "Create New Account" \
        "Import Existing Account")
    
    case "$setup_choice" in
        "Create New Account")
            echo ""
            msg_info "Creating new Casper account..."
            
            local name="user"
            
            if generate_identity_key "$name"; then
                # Verify the key was actually created
                if [[ -f "$KEYS_DIR/${name}.pem" ]]; then
                    msg_success "New account created successfully!"
                    echo ""
                    
                    # Get and display the public key
                    local public_key
                    public_key=$(casper-client account-address --public-key "$KEYS_DIR/${name}.pem" 2>/dev/null | grep -oE '^[a-f0-9]+' | head -1)
                    
                    if [[ -n "$public_key" ]]; then
                        echo -e "  ${C_BOLD}Your Public Key:${C_RESET}"
                        echo -e "  ${C_CYAN}${public_key}${C_RESET}"
                        echo ""
                        echo -e "${C_WARN}${ICON_WARN} Important: Request testnet CSPR from the faucet to fund your account.${C_RESET}"
                        echo -e "  ${C_DIM}https://testnet.cspr.live/tools/faucet${C_RESET}"
                    fi
                    
                    # Add to identities
                    IDENTITIES["$name"]="${name}.pem:Primary trading account"
                    set_current_identity "$name"
                    
                    echo ""
                    ~/.local/bin/gum input --placeholder "Press Enter to continue..."
                else
                    msg_error "Key generation failed - no key file created"
                    return 1
                fi
            else
                msg_error "Failed to generate key pair"
                return 1
            fi
            ;;
            
        "Import Existing Account")
            echo ""
            msg_info "Import your existing Casper secret key"
            echo -e "${C_DIM}Provide the path to your secret_key.pem file${C_RESET}"
            echo ""
            
            local key_path
            key_path=$(~/.local/bin/gum input --placeholder "Path to secret_key.pem (e.g., ~/my_wallet/secret_key.pem)")
            
            # Expand ~ to home directory
            key_path="${key_path/#\~/$HOME}"
            
            if [[ -z "$key_path" ]]; then
                msg_error "No path provided"
                return 1
            fi
            
            if import_secret_key "user" "$key_path"; then
                # Add to identities
                IDENTITIES["user"]="user.pem:Imported account"
                set_current_identity "user"
                
                # Verify and show public key
                local public_key
                public_key=$(casper-client account-address --public-key "$KEYS_DIR/user.pem" 2>/dev/null | grep -oE '^[a-f0-9]+' | head -1)
                
                if [[ -n "$public_key" ]]; then
                    echo ""
                    echo -e "  ${C_BOLD}Imported Account:${C_RESET}"
                    echo -e "  ${C_CYAN}${public_key}${C_RESET}"
                fi
                
                echo ""
                ~/.local/bin/gum input --placeholder "Press Enter to continue..."
            else
                return 1
            fi
            ;;
    esac
    
    return 0
}

ensure_default_identities() {
    # First check if super.keys exists - if so, we're good
    if [[ -f "$SUPER_KEYS_FILE" ]]; then
        # Super.keys found - ensure user.pem is created from it
        load_super_keys
        
        # Set user as current identity if not set
        if [[ ! -f "$CURRENT_IDENTITY_FILE" ]]; then
            set_current_identity "user"
        fi
        return 0
    fi
    
    # Check if ANY .pem files exist in KEYS_DIR
    local pem_count
    pem_count=$(find "$KEYS_DIR" -maxdepth 1 -name "*.pem" -type f 2>/dev/null | wc -l)
    
    if [[ "$pem_count" -eq 0 ]]; then
        # No keys exist - run first-time setup
        first_time_setup
    else
        # Keys exist - verify user.pem is present and set as default if no current identity
        if [[ ! -f "$CURRENT_IDENTITY_FILE" ]]; then
            # Find first available .pem and set as current
            local first_key
            first_key=$(find "$KEYS_DIR" -maxdepth 1 -name "*.pem" -type f | head -1 | xargs basename | sed 's/.pem$//')
            if [[ -n "$first_key" ]]; then
                set_current_identity "$first_key"
            fi
        fi
    fi
}

ensure_default_identities
