#!/bin/bash
# Bastion TUI - Local Ledger
# Transaction history with fzf filtering

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

LEDGER_FILE="$(dirname "$SCRIPT_DIR")/../.bastion_history.json"

# ═══════════════════════════════════════════════════════════════════
# Ledger Initialization
# ═══════════════════════════════════════════════════════════════════

init_ledger() {
    if [[ ! -f "$LEDGER_FILE" ]]; then
        echo '{"transactions":[]}' > "$LEDGER_FILE"
    fi
}

# ═══════════════════════════════════════════════════════════════════
# Fetch On-Chain Transactions from Testnet
# ═══════════════════════════════════════════════════════════════════

fetch_onchain_transactions() {
    local limit="${1:-10}"
    
    # Get current identity's public key
    local public_key=""
    if [[ -n "$SUPER_PUBLIC_KEY" ]]; then
        public_key="$SUPER_PUBLIC_KEY"
    fi
    
    if [[ -z "$public_key" ]]; then
        echo "[]"
        return 1
    fi
    
    # Fetch from REST API
    local result
    result=$(get_account_transfers "$public_key" "$limit" 2>/dev/null)
    
    if [[ -z "$result" ]]; then
        echo "[]"
        return 1
    fi
    
    # Parse and format the transactions
    echo "$result" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    transfers = data.get('data', [])
    
    formatted = []
    for t in transfers:
        tx = {
            'hash': t.get('deploy_hash', 'N/A'),
            'type': 'transfer',
            'amount': str(int(t.get('amount', 0)) / 1e9) + ' CSPR',
            'timestamp': t.get('timestamp', ''),
            'status': 'success',
            'from': t.get('initiator_account_hash', '')[:16] + '...' if t.get('initiator_account_hash') else 'N/A',
            'to': t.get('to_account_hash', '')[:16] + '...' if t.get('to_account_hash') else 'N/A',
            'onchain': True
        }
        formatted.append(tx)
    
    print(json.dumps(formatted))
except Exception as e:
    print('[]')
" 2>/dev/null || echo "[]"
}

list_onchain_transactions() {
    local limit="${1:-10}"
    
    echo -e "${C_BOLD}${C_CYAN}📡 On-Chain Transfers (Live from Testnet)${C_RESET}"
    echo ""
    
    local txs
    txs=$(fetch_onchain_transactions "$limit")
    
    if [[ "$txs" == "[]" || -z "$txs" ]]; then
        echo -e "${C_DIM}  No on-chain transactions found or unable to fetch.${C_RESET}"
        return 1
    fi
    
    echo "$txs" | python3 -c "
import sys, json
from datetime import datetime

data = json.load(sys.stdin)

if not data:
    print('  No transactions found.')
else:
    print(f\"  {'Status':<8} {'Type':<10} {'Amount':<18} {'Hash':<22} {'Time':<16}\")
    print('  ' + '─' * 80)
    
    for tx in data[:10]:
        status = '✓'
        type_str = '📤 ' + tx.get('type', 'unknown')
        amount = tx.get('amount', '0')
        hash_short = tx.get('hash', '')[:18] + '...'
        
        try:
            ts = datetime.fromisoformat(tx.get('timestamp', '').replace('Z', '+00:00'))
            time_str = ts.strftime('%m/%d %H:%M')
        except:
            time_str = tx.get('timestamp', '')[:16]
        
        print(f\"  {status:<8} {type_str:<10} {amount:<18} {hash_short:<22} {time_str:<16}\")
" 2>/dev/null
}

# ═══════════════════════════════════════════════════════════════════
# Add Transaction
# ═══════════════════════════════════════════════════════════════════

add_transaction() {
    local tx_hash="$1"
    local type="$2"      # mint, swap, deposit, order
    local amount="$3"
    local status="$4"    # pending, success, failed
    local identity="$5"
    local extra="$6"     # Additional data (JSON)
    
    init_ledger
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local id=$(openssl rand -hex 8)
    
    # Escape extra JSON for safe Python interpolation
    local extra_escaped=$(echo "$extra" | sed 's/"/\\"/g')
    
    python3 << PYEOF
import json

ledger_file = "$LEDGER_FILE"

with open(ledger_file, 'r') as f:
    data = json.load(f)

tx = {
    "id": "$id",
    "hash": "$tx_hash",
    "type": "$type",
    "amount": "$amount",
    "timestamp": "$timestamp",
    "status": "$status",
    "identity": "$identity"
}

extra_str = '$extra'
if extra_str and extra_str.strip():
    try:
        tx["extra"] = json.loads(extra_str)
    except:
        pass

data["transactions"].append(tx)

with open(ledger_file, 'w') as f:
    json.dump(data, f, indent=2)
PYEOF
}

# ═══════════════════════════════════════════════════════════════════
# Update Transaction Status
# ═══════════════════════════════════════════════════════════════════

update_transaction_status() {
    local tx_hash="$1"
    local status="$2"
    
    python3 << EOF
import json

with open('$LEDGER_FILE', 'r') as f:
    data = json.load(f)

for tx in data["transactions"]:
    if tx["hash"] == "$tx_hash":
        tx["status"] = "$status"
        break

with open('$LEDGER_FILE', 'w') as f:
    json.dump(data, f, indent=2)
EOF
}

# ═══════════════════════════════════════════════════════════════════
# List Transactions
# ═══════════════════════════════════════════════════════════════════

list_transactions() {
    local filter_type="$1"
    local limit="${2:-20}"
    
    init_ledger
    
    python3 << EOF
import json
from datetime import datetime

with open('$LEDGER_FILE', 'r') as f:
    data = json.load(f)

txs = data.get("transactions", [])

# Filter by type if specified
filter_type = "$filter_type"
if filter_type:
    txs = [t for t in txs if t.get("type") == filter_type]

# Sort by timestamp (newest first)
txs = sorted(txs, key=lambda x: x.get("timestamp", ""), reverse=True)[:$limit]

# Status icons
status_icons = {
    "success": "✓",
    "failed": "✗",
    "pending": "◐"
}

# Type icons
type_icons = {
    "mint": "🪙",
    "swap": "🔄",
    "deposit": "💰",
    "order": "📜",
    "withdraw": "📤"
}

if not txs:
    print("No transactions found.")
else:
    print(f"{'Status':<8} {'Type':<10} {'Amount':<15} {'Hash':<20} {'Time':<20}")
    print("─" * 80)
    
    for tx in txs:
        status = status_icons.get(tx.get("status", "pending"), "?")
        type_icon = type_icons.get(tx.get("type", ""), "•")
        type_str = f"{type_icon} {tx.get('type', 'unknown')}"
        amount = tx.get("amount", "0")
        hash_short = tx.get("hash", "")[:16] + "..."
        
        # Format timestamp
        try:
            ts = datetime.fromisoformat(tx.get("timestamp", "").replace("Z", "+00:00"))
            time_str = ts.strftime("%m/%d %H:%M")
        except:
            time_str = tx.get("timestamp", "")[:16]
        
        print(f"{status:<8} {type_str:<10} {amount:<15} {hash_short:<20} {time_str:<20}")
EOF
}

# ═══════════════════════════════════════════════════════════════════
# Interactive History Browser
# ═══════════════════════════════════════════════════════════════════

history_browser() {
    init_ledger
    
    clear_screen
    show_banner
    draw_section "Transaction History"
    
    # Get all transactions as formatted lines
    local tx_lines
    tx_lines=$(python3 << PYEOF
import json

with open('$LEDGER_FILE', 'r') as f:
    data = json.load(f)

for tx in sorted(data.get("transactions", []), key=lambda x: x.get("timestamp", ""), reverse=True):
    status = "✓" if tx.get("status") == "success" else "✗" if tx.get("status") == "failed" else "◐"
    print(f"{status} | {tx.get('type', ''):<8} | {tx.get('amount', ''):<12} | {tx.get('hash', '')[:20]}... | {tx.get('timestamp', '')[:16]}")
PYEOF
)
    
    if [[ -z "$tx_lines" ]]; then
        msg_info "No transactions recorded yet."
        echo ""
        ~/.local/bin/gum input --placeholder "Press Enter to continue..."
        return
    fi
    
    # Use gum filter for interactive selection
    local selected
    selected=$(echo "$tx_lines" | ~/.local/bin/gum filter --placeholder "Search transactions..." --height 15)
    
    if [[ -n "$selected" ]]; then
        # Extract hash from selected line
        local hash=$(echo "$selected" | grep -oP '[a-f0-9]{20}')
        
        # Show transaction details
        echo ""
        draw_section "Transaction Details"
        python3 << PYEOF
import json

with open('$LEDGER_FILE', 'r') as f:
    data = json.load(f)

for tx in data.get("transactions", []):
    if tx.get("hash", "").startswith("$hash"):
        print(f"  Hash:      {tx.get('hash', 'N/A')}")
        print(f"  Type:      {tx.get('type', 'N/A')}")
        print(f"  Amount:    {tx.get('amount', 'N/A')}")
        print(f"  Status:    {tx.get('status', 'N/A')}")
        print(f"  Identity:  {tx.get('identity', 'N/A')}")
        print(f"  Timestamp: {tx.get('timestamp', 'N/A')}")
        break
PYEOF
    fi
    
    echo ""
    ~/.local/bin/gum input --placeholder "Press Enter to continue..."
}

# ═══════════════════════════════════════════════════════════════════
# Ledger Menu
# ═══════════════════════════════════════════════════════════════════

ledger_menu() {
    while true; do
        clear_screen
        show_banner
        draw_section "Transaction Ledger"
        
        # Show on-chain transactions first (real data)
        list_onchain_transactions 5
        echo ""
        
        echo -e "${C_BOLD}${C_WHITE}📋 Local Transaction History${C_RESET}"
        echo ""
        list_transactions "" 5
        echo ""
        
        local choice
        choice=$(~/.local/bin/gum choose \
            "View On-Chain Transfers" \
            "Browse Local History" \
            "Filter by Type" \
            "Export to CSV" \
            "← Back to Main Menu")
        
        case "$choice" in
            "View On-Chain Transfers")
                clear_screen
                show_banner
                draw_section "On-Chain Transfers"
                list_onchain_transactions 20
                echo ""
                ~/.local/bin/gum input --placeholder "Press Enter to continue..."
                ;;
            "Browse Local History")
                history_browser
                ;;
            "Filter by Type")
                local type
                type=$(~/.local/bin/gum choose "mint" "swap" "deposit" "order" "withdraw")
                clear_screen
                draw_section "Transactions: $type"
                list_transactions "$type" 20
                echo ""
                ~/.local/bin/gum input --placeholder "Press Enter to continue..."
                ;;
            "Export to CSV")
                local csv_file="bastion_history_$(date +%Y%m%d).csv"
                python3 << EOF
import json
import csv

with open('$LEDGER_FILE', 'r') as f:
    data = json.load(f)

with open('$csv_file', 'w', newline='') as f:
    writer = csv.writer(f)
    writer.writerow(['Hash', 'Type', 'Amount', 'Status', 'Identity', 'Timestamp'])
    for tx in data.get('transactions', []):
        writer.writerow([
            tx.get('hash', ''),
            tx.get('type', ''),
            tx.get('amount', ''),
            tx.get('status', ''),
            tx.get('identity', ''),
            tx.get('timestamp', '')
        ])
print("Exported to $csv_file")
EOF
                msg_success "Exported to $csv_file"
                sleep 1
                ;;
            "← Back to Main Menu"|"")
                break
                ;;
        esac
    done
}
