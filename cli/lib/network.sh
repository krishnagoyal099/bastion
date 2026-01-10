#!/bin/bash
# Bastion TUI - Network Library
# RPC calls and status checks


# ═══════════════════════════════════════════════════════════════════
# Configuration
# ═══════════════════════════════════════════════════════════════════
CSPR_CLOUD_API_KEY="${CSPR_CLOUD_API_KEY:-019baaf7-e535-7727-8cf9-be312a208df2}"
CSPR_CLOUD_RPC="${CSPR_CLOUD_RPC:-https://node.testnet.cspr.cloud/rpc}"
CHAIN_NAME="${CHAIN_NAME:-casper-test}"

# Contract hashes
TOKEN_HASH="hash-64d47b728ae3ea2b147bc4660cad93a56577ffd798e17e022056b85b3643d6b4"
AMM_HASH="hash-f6261e8cd55db234f7a6525b7cedaa53123b510aace8f0cf02bcf0dd25524636"
BASTION_HASH="hash-9b1ee8aed8931f05cf8efd0eb92f1dab473f1b9c0a9c4c0b8b83ec38db0598c9"

# ═══════════════════════════════════════════════════════════════════
# RPC Helper
# ═══════════════════════════════════════════════════════════════════
rpc_call() {
    local method="$1"
    local params="$2"
    
    curl -s -X POST "$CSPR_CLOUD_RPC" \
        -H "Content-Type: application/json" \
        -H "Authorization: $CSPR_CLOUD_API_KEY" \
        -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"$method\",\"params\":$params}"
}

# ═══════════════════════════════════════════════════════════════════
# Network Status
# ═══════════════════════════════════════════════════════════════════
get_block_height() {
    local result
    result=$(rpc_call "info_get_status" "{}")
    echo "$result" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    height = data.get('result', {}).get('last_added_block_info', {}).get('height', 'N/A')
    print(height)
except:
    print('N/A')
" 2>/dev/null || echo "N/A"
}

check_connection() {
    local result
    result=$(rpc_call "info_get_status" "{}" 2>/dev/null)
    if echo "$result" | grep -q "result"; then
        echo "connected"
    else
        echo "disconnected"
    fi
}

# ═══════════════════════════════════════════════════════════════════
# Account Functions
# ═══════════════════════════════════════════════════════════════════
get_account_hash() {
    local key_file="$1"
    casper-client account-address --public-key "$key_file" 2>/dev/null | grep -oP 'account-hash-\K[a-f0-9]+'
}

get_balance() {
    local account_hash="$1"
    local result
    result=$(rpc_call "query_balance" "{\"purse_identifier\":{\"main_purse_under_account_hash\":\"account-hash-$account_hash\"}}")
    echo "$result" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    balance = int(data.get('result', {}).get('balance', '0'))
    print(f'{balance / 1e9:.2f}')
except:
    print('0.00')
" 2>/dev/null || echo "0.00"
}

# ═══════════════════════════════════════════════════════════════════
# Transaction Functions
# ═══════════════════════════════════════════════════════════════════
submit_transaction() {
    local tx_json_file="$1"
    
    local request
    request=$(echo "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"account_put_transaction\",\"params\":{\"transaction\":$(cat "$tx_json_file")}}")
    
    curl -s -X POST "$CSPR_CLOUD_RPC" \
        -H "Content-Type: application/json" \
        -H "Authorization: $CSPR_CLOUD_API_KEY" \
        -d "$request"
}

check_transaction() {
    local tx_hash="$1"
    
    rpc_call "info_get_transaction" "{\"transaction_hash\":{\"Version1\":\"$tx_hash\"},\"finalized_approvals\":true}"
}

wait_for_transaction() {
    local tx_hash="$1"
    local timeout="${2:-60}"
    local start_time=$(date +%s)
    
    while true; do
        local elapsed=$(( $(date +%s) - start_time ))
        if (( elapsed > timeout )); then
            return 1
        fi
        
        local result
        result=$(check_transaction "$tx_hash")
        
        if echo "$result" | grep -q "execution_info"; then
            if echo "$result" | grep -q "error_message"; then
                local error
                error=$(echo "$result" | python3 -c "
import sys, json
data = json.load(sys.stdin)
err = data.get('result',{}).get('execution_info',{}).get('execution_result',{}).get('Version2',{}).get('error_message','')
print(err)
")
                echo "FAILED:$error"
                return 2
            else
                echo "SUCCESS"
                return 0
            fi
        fi
        
        sleep 2
    done
}

# ═══════════════════════════════════════════════════════════════════
# Pool/AMM Functions
# ═══════════════════════════════════════════════════════════════════
get_pool_reserves() {
    # This would query the AMM contract for reserves
    # For now, return simulated values
    echo "125000:3125"  # CSPR:mUSD
}

calculate_swap_output() {
    local amount_in="$1"
    local reserve_in="$2"
    local reserve_out="$3"
    
    # x * y = k formula with 0.3% fee
    python3 -c "
amount_in = float('$amount_in')
reserve_in = float('$reserve_in')
reserve_out = float('$reserve_out')

amount_in_with_fee = amount_in * 0.997
numerator = amount_in_with_fee * reserve_out
denominator = reserve_in + amount_in_with_fee
amount_out = numerator / denominator

print(f'{amount_out:.4f}')
"
}
