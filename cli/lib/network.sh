#!/bin/bash
# Bastion TUI - Network Library
# RPC calls and status checks


# ═══════════════════════════════════════════════════════════════════
# Configuration
# ═══════════════════════════════════════════════════════════════════
CSPR_CLOUD_API_KEY="${CSPR_CLOUD_API_KEY:-019bb231-955c-722e-b0ba-377cccb8c2d6}"
CSPR_CLOUD_RPC="${CSPR_CLOUD_RPC:-https://node.testnet.cspr.cloud/rpc}"
CSPR_CLOUD_REST="${CSPR_CLOUD_REST:-https://api.testnet.cspr.cloud}"
CHAIN_NAME="${CHAIN_NAME:-casper-test}"

# Contract hashes
TOKEN_HASH="hash-64d47b728ae3ea2b147bc4660cad93a56577ffd798e17e022056b85b3643d6b4"
AMM_HASH="hash-f6261e8cd55db234f7a6525b7cedaa53123b510aace8f0cf02bcf0dd25524636"
BASTION_HASH="hash-9b1ee8aed8931f05cf8efd0eb92f1dab473f1b9c0a9c4c0b8b83ec38db0598c9"

# ═══════════════════════════════════════════════════════════════════
# RPC Helper (for blockchain state/transactions)
# ═══════════════════════════════════════════════════════════════════
rpc_call() {
    local method="$1"
    local params="$2"
    local timeout="${3:-5}"
    
    curl -s --max-time "$timeout" -X POST "$CSPR_CLOUD_RPC" \
        -H "Content-Type: application/json" \
        -H "Authorization: $CSPR_CLOUD_API_KEY" \
        -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"$method\",\"params\":$params}" 2>/dev/null
}

# ═══════════════════════════════════════════════════════════════════
# REST API Helper (for account data, transfers, deploys)
# ═══════════════════════════════════════════════════════════════════
rest_api_call() {
    local endpoint="$1"
    local timeout="${2:-5}"
    
    curl -s --max-time "$timeout" -X GET "${CSPR_CLOUD_REST}${endpoint}" \
        -H "accept: application/json" \
        -H "authorization: $CSPR_CLOUD_API_KEY" 2>/dev/null
}

# Get account info by public key using REST API
get_account_info() {
    local public_key="$1"
    rest_api_call "/accounts/${public_key}"
}

# Get account balance in CSPR using REST API
get_account_balance_rest() {
    local public_key="$1"
    local result
    result=$(get_account_info "$public_key")
    
    echo "$result" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    balance = int(data.get('data', {}).get('balance', '0'))
    print(f'{balance / 1e9:.2f}')
except:
    print('0.00')
" 2>/dev/null || echo "0.00"
}

# Get account transfers using REST API
get_account_transfers() {
    local public_key="$1"
    local limit="${2:-10}"
    rest_api_call "/accounts/${public_key}/transfers?page_size=${limit}"
}

# ═══════════════════════════════════════════════════════════════════
# Network Status
# ═══════════════════════════════════════════════════════════════════
get_block_height() {
    local result height
    
    # Try REST API first (more reliable)
    result=$(curl -s --max-time 3 -X GET "${CSPR_CLOUD_REST}/blocks?page=1&page_size=1" \
        -H "accept: application/json" \
        -H "authorization: $CSPR_CLOUD_API_KEY" 2>/dev/null)
    
    if [[ -n "$result" ]]; then
        height=$(echo "$result" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    blocks = data.get('data', [])
    if blocks and len(blocks) > 0:
        print(blocks[0].get('height', 'N/A'))
    else:
        print('N/A')
except:
    print('N/A')
" 2>/dev/null)
        
        if [[ "$height" != "N/A" && -n "$height" ]]; then
            echo "$height"
            return
        fi
    fi
    
    # Fallback to RPC
    result=$(rpc_call "info_get_status" "{}" 3)
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
    
    # Try REST API first (more reliable than RPC)
    result=$(curl -s --max-time 5 -X GET "${CSPR_CLOUD_REST}/blocks?page=1&page_size=1" \
        -H "accept: application/json" \
        -H "authorization: $CSPR_CLOUD_API_KEY" 2>/dev/null)
    
    if echo "$result" | grep -q '"data"'; then
        echo "connected"
        return
    fi
    
    # Fallback to RPC check
    result=$(rpc_call "info_get_status" "{}" 5 2>/dev/null)
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

query_contract_key() {
    local contract_hash="$1"
    local key_name="$2"
    
    local result
    result=$(rpc_call "query_global_state" "{\"state_identifier\":{\"StateRootHash\":null},\"key\":\"$contract_hash\",\"path\":[\"$key_name\"]}")
    
    echo "$result" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    stored = data.get('result', {}).get('stored_value', {})
    # Handle CLValue
    if 'CLValue' in stored:
        val = stored['CLValue'].get('parsed', stored['CLValue'].get('bytes', 'N/A'))
        print(val)
    else:
        print('N/A')
except Exception as e:
    print('N/A')
" 2>/dev/null || echo "N/A"
}

get_pool_reserves() {
    # Query the AMM contract for real reserves
    local reserve_a reserve_b
    
    # Try to get real data from testnet
    reserve_a=$(query_contract_key "$AMM_HASH" "reserve_a" 2>/dev/null)
    reserve_b=$(query_contract_key "$AMM_HASH" "reserve_b" 2>/dev/null)
    
    # Validate the response
    if [[ "$reserve_a" == "N/A" || "$reserve_b" == "N/A" || -z "$reserve_a" || -z "$reserve_b" ]]; then
        # Contract not available or error - return indicator values
        echo "ERROR:CONTRACT_UNAVAILABLE"
        return 1
    fi
    
    # Convert from motes if needed (if > 1 billion, assume motes)
    if [[ "$reserve_a" =~ ^[0-9]+$ ]] && (( reserve_a > 1000000000 )); then
        reserve_a=$(python3 -c "print(int($reserve_a / 1e9))")
    fi
    if [[ "$reserve_b" =~ ^[0-9]+$ ]] && (( reserve_b > 1000000000 )); then
        reserve_b=$(python3 -c "print(round($reserve_b / 1e9, 2))")
    fi
    
    echo "${reserve_a}:${reserve_b}"
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
