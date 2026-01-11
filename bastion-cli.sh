#!/bin/bash
# Quick-start script for Bastion DeFi Platform

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'


# Logo
echo -e "${GREEN}
    ____            __  _           
   / __ )____ _____/ /_(_)___  ____ 
  / __  / __ \`/ __/ __/ / __ \/ __ \\
 / /_/ / /_/ (__  ) /_/ / /_/ / / / /
/_____/\__,_/____/\__/_/\____/_/ /_/ 
                                     
    ${BLUE}Dark Pool Trading on Casper${NC}
"

echo -e "${BLUE}===========================================${NC}"

# Configuration
export CSPR_CLOUD_API_KEY="019baaf7-e535-7727-8cf9-be312a208df2"
export CHAIN_NAME="casper-test"
export SECRET_KEY="./secret_key.pem"
export ACCOUNT_KEY="account-hash-9833bf9ef9c422aa2b481e212c9c4a40018c23d97909e846e6dde4640ab2e46b"

# Contract hashes
TOKEN_HASH="hash-64d47b728ae3ea2b147bc4660cad93a56577ffd798e17e022056b85b3643d6b4"
AMM_HASH="hash-f6261e8cd55db234f7a6525b7cedaa53123b510aace8f0cf02bcf0dd25524636"
BASTION_HASH="hash-9b1ee8aed8931f05cf8efd0eb92f1dab473f1b9c0a9c4c0b8b83ec38db0598c9"

echo -e "${GREEN}✅ Configured contracts:${NC}"
echo "   Token: $TOKEN_HASH"
echo "   AMM: $AMM_HASH"
echo "   Bastion: $BASTION_HASH"
echo ""

# Menu
PS3='Select operation: '
options=("Mint Tokens" "Deposit to Bastion" "Submit Order" "Swap Tokens" "Check Transaction" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Mint Tokens")
            echo -e "${BLUE}Minting 1000 BastionUSD tokens...${NC}"
            read -p "Amount (default: 1000000000000): " AMOUNT
            AMOUNT=${AMOUNT:-1000000000000}
            
            casper-client make-transaction invocable-entity \
              --chain-name "$CHAIN_NAME" \
              --secret-key "$SECRET_KEY" \
              --contract-hash "$TOKEN_HASH" \
              --session-entry-point "mint" \
              --session-arg "owner:key='$ACCOUNT_KEY'" \
              --session-arg "amount:u256='$AMOUNT'" \
              --payment-amount 5000000000 \
              --standard-payment true \
              --gas-price-tolerance 10 \
              > /tmp/mint_tx.json
            
            echo "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"account_put_transaction\",\"params\":{\"transaction\":$(cat /tmp/mint_tx.json)}}" | \
            curl -s -X POST "https://node.testnet.cspr.cloud/rpc" \
              -H "Content-Type: application/json" \
              -H "Authorization: $CSPR_CLOUD_API_KEY" \
              -d @- | python3 -c "
import sys, json
data = json.load(sys.stdin)
if 'result' in data:
    tx = data['result'].get('transaction_hash', {})
    tx_hash = tx.get('Version1', tx) if isinstance(tx, dict) else tx
    print(f'✅ Submitted: {tx_hash}')
    print(f'View: https://testnet.cspr.live/transaction/{tx_hash}')
else:
    print('Error:', data)
"
            ;;
        "Deposit to Bastion")
            echo -e "${BLUE}Depositing CSPR to Bastion...${NC}"
            read -p "Amount in motes (default: 1000000000): " AMOUNT
            AMOUNT=${AMOUNT:-1000000000}
            
            casper-client make-transaction invocable-entity \
              --chain-name "$CHAIN_NAME" \
              --secret-key "$SECRET_KEY" \
              --contract-hash "$BASTION_HASH" \
              --session-entry-point "deposit_cspr" \
              --session-arg "amount:u256='$AMOUNT'" \
              --payment-amount 5000000000 \
              --standard-payment true \
              --gas-price-tolerance 10 \
              > /tmp/deposit_tx.json
            
            echo "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"account_put_transaction\",\"params\":{\"transaction\":$(cat /tmp/deposit_tx.json)}}" | \
            curl -s -X POST "https://node.testnet.cspr.cloud/rpc" \
              -H "Content-Type: application/json" \
              -H "Authorization: $CSPR_CLOUD_API_KEY" \
              -d @-
            ;;
        "Submit Order")
            echo -e "${BLUE}Submitting encrypted order to Bastion...${NC}"
            read -p "Amount (default: 100000000): " AMOUNT
            AMOUNT=${AMOUNT:-100000000}
            
            # Generate random commitment (32 bytes)
            COMMITMENT=$(openssl rand -hex 32)
            
            casper-client make-transaction invocable-entity \
              --chain-name "$CHAIN_NAME" \
              --secret-key "$SECRET_KEY" \
              --contract-hash "$BASTION_HASH" \
              --session-entry-point "submit_order" \
              --session-arg "is_cspr:bool='true'" \
              --session-arg "amount:u256='$AMOUNT'" \
              --session-arg "commitment:bytes='$COMMITMENT'" \
              --session-arg "proof:bytes='00'" \
              --payment-amount 10000000000 \
              --standard-payment true \
              --gas-price-tolerance 10 \
              > /tmp/order_tx.json
            
            echo "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"account_put_transaction\",\"params\":{\"transaction\":$(cat /tmp/order_tx.json)}}" | \
            curl -s -X POST "https://node.testnet.cspr.cloud/rpc" \
              -H "Content-Type: application/json" \
              -H "Authorization: $CSPR_CLOUD_API_KEY" \
              -d @-
            ;;
        "Swap Tokens")
            echo -e "${BLUE}Token swap via AMM...${NC}"
            echo "1) Swap A -> B"
            echo "2) Swap B -> A"
            read -p "Choice: " CHOICE
            read -p "Amount in (default: 100000000): " AMOUNT_IN
            AMOUNT_IN=${AMOUNT_IN:-100000000}
            read -p "Min amount out (default: 95000000): " AMOUNT_OUT
            AMOUNT_OUT=${AMOUNT_OUT:-95000000}
            
            ENTRY_POINT="swap_a_to_b"
            if [ "$CHOICE" = "2" ]; then
                ENTRY_POINT="swap_b_to_a"
            fi
            
            casper-client make-transaction invocable-entity \
              --chain-name "$CHAIN_NAME" \
              --secret-key "$SECRET_KEY" \
              --contract-hash "$AMM_HASH" \
              --session-entry-point "$ENTRY_POINT" \
              --session-arg "amount_in:u256='$AMOUNT_IN'" \
              --session-arg "min_amount_out:u256='$AMOUNT_OUT'" \
              --payment-amount 5000000000 \
              --standard-payment true \
              --gas-price-tolerance 10 \
              > /tmp/swap_tx.json
            
            echo "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"account_put_transaction\",\"params\":{\"transaction\":$(cat /tmp/swap_tx.json)}}" | \
            curl -s -X POST "https://node.testnet.cspr.cloud/rpc" \
              -H "Content-Type: application/json" \
              -H "Authorization: $CSPR_CLOUD_API_KEY" \
              -d @-
            ;;
        "Check Transaction")
            read -p "Transaction hash: " TX_HASH
            
            curl -s -X POST "https://node.testnet.cspr.cloud/rpc" \
              -H "Content-Type: application/json" \
              -H "Authorization: $CSPR_CLOUD_API_KEY" \
              -d "{
                \"jsonrpc\":\"2.0\",
                \"id\":1,
                \"method\":\"info_get_transaction\",
                \"params\":{
                  \"transaction_hash\":{\"Version1\":\"$TX_HASH\"},
                  \"finalized_approvals\":true
                }
              }" | python3 -c "
import sys, json
data = json.load(sys.stdin)
exec_info = data.get('result', {}).get('execution_info')
if exec_info:
    result = exec_info.get('execution_result', {}).get('Version2', {})
    error = result.get('error_message')
    if error:
        print(f'❌ Failed: {error}')
    else:
        print('✅ Success!')
    print(f'Gas: {int(result.get(\"consumed\", 0))/1e9:.2f} CSPR')
else:
    print('⏳ Still processing or not found')
"
            ;;
        "Quit")
            break
            ;;
        *) echo "Invalid option";;
    esac
    echo ""
done

echo -e "${GREEN}Thank you for using Bastion DeFi Platform!${NC}"
