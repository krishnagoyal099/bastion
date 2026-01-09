# StorySwap AMM - Visual Storytelling DEX

## Overview
StorySwap is a **grand AMM** (Automated Market Maker) contract designed with visual storytelling in mind. Every swap, liquidity event, and pool state change is tracked and exposed for rich UI animations.

---

## 🎨 **Visual Features for UI Storytelling**

### 1. **Liquidity Pool Visualization**
- Live reserve tracking (`get_reserves()`)
- Pool ratio calculations
- Total value locked (TVL) metrics
- LP share distribution

### 2. **Swap Animations**
- Price impact visualization
- Input → Calculation → Output flow
- Real-time price updates
- Transaction history via events

### 3. **Provider Stats**
- Individual LP share tracking
- Contribution percentage
- Rewards/fees accumulation
- Add/remove liquidity history

### 4. **Pool Health Metrics**
- Reserve balance ratios
- Total swaps counter
- Liquidity depth indicators
- Fee accumulation tracking

---

## 📊 **Contract Architecture**

### **Core Functions:**

#### Initialization
```rust
initialize(token_a: ContractHash, token_b: ContractHash)
```
- Sets up the liquidity pool with two CEP-18 tokens
- Creates all necessary storage dictionaries
- Configures 0.3% swap fee (Uniswap V2 standard)

#### Liquidity Management
```rust
add_liquidity(amount_a: U256, amount_b: U256) -> U256
```
- Adds liquidity to the pool
- Returns LP shares minted
- Emits event for UI tracking
- First LP gets shares = sqrt(amount_a * amount_b)
- Subsequent LPs get proportional shares

```rust
remove_liquidity(shares: U256) -> (U256, U256)
```
- Burns LP shares
- Returns proportional amounts of both tokens
- Updates reserves
- Emits event for UI

#### Swapping
```rust
swap_a_for_b(amount_in: U256, min_amount_out: U256) -> U256
swap_b_for_a(amount_in: U256, min_amount_out: U256) -> U256
```
- Constant product formula: `x * y = k`
- 0.3% fee on input amount
- Slippage protection via `min_amount_out`
- Emits detailed swap events
- Updates swap counter

#### Query Functions (Gas-free for UI)
```rust
get_reserves() -> (U256, U256)
get_user_shares(user: Key) -> U256
get_total_shares() -> U256
get_swap_count() -> u64
quote_swap_a_to_b(amount_in: U256) -> U256
quote_swap_b_to_a(amount_in: U256) -> U256
```

---

## 💡 **Pricing Formula**

### Constant Product AMM
```
x * y = k  (where k is constant)
```

### Swap Calculation (with 0.3% fee)
```
amount_out = (amount_in * 997 * reserve_out) / (reserve_in * 1000 + amount_in * 997)
```

### Price Impact
```
price_impact = (amount_in / reserve_in) * 100
```

### LP Share Calculation
```
First LP:  shares = sqrt(amount_a * amount_b) - MIN_LIQUIDITY
Next LPs:  shares = min(
             (amount_a * total_shares) / reserve_a,
             (amount_b * total_shares) / reserve_b
           )
```

---

## 🎬 **Event System for UI Animations**

### Swap Events
Stored in `swap_events` dictionary:
```json
{
  "type": "swap",
  "direction": "a_to_b" | "b_to_a",
  "trader": "account-hash-xxx",
  "amount_in": "1000000000",
  "amount_out": "950000000",
  "reserve_a": "10000000000",
  "reserve_b": "9500000000"
}
```

### Liquidity Events
Stored in `liquidity_events` dictionary:
```json
{
  "type": "liquidity",
  "action": "add" | "remove",
  "provider": "account-hash-xxx",
  "amount_a": "1000000",
  "amount_b": "2000000",
  "shares": "1414213"
}
```

---

## 🚀 **Deployment Guide**

### Prerequisites
1. Two CEP-18 tokens deployed (e.g., BastionUSD + CSPR wrapper)
2. Casper testnet account with CSPR for gas
3. Casper-client installed

### Deploy Steps

```bash
# 1. Build the contract
cd amm_contract
cargo build --release --target wasm32-unknown-unknown

# 2. Deploy to testnet
casper-client put-transaction \
    --node-address https://node.testnet.cspr.cloud/rpc \
    --chain-name casper-test \
    --secret-key ~/secret_key.pem \
    --payment-amount 200000000000 \
    --session-path target/wasm32-unknown-unknown/release/storyswap_amm.wasm

# 3. Initialize the pool
casper-client put-transaction \
    --node-address https://node.testnet.cspr.cloud/rpc \
    --chain-name casper-test \
    --secret-key ~/secret_key.pem \
    --session-hash hash-XXXXX \
    --session-entry-point initialize \
    --session-arg "token_a:key='hash-TOKEN_A_HASH'" \
    --session-arg "token_b:key='hash-TOKEN_B_HASH'" \
    --payment-amount 5000000000
```

---

## 🎨 **UI Integration Examples**

### 1. **Animated Swap Flow**
```typescript
// Quote the swap (no gas)
const amountOut = await contract.quote_swap_a_to_b(amountIn);

// Show animation: Input → Processing → Output
animateSwap({
  from: 'TokenA',
  to: 'TokenB',
  amountIn,
  amountOut,
  priceImpact: calculatePriceImpact(amountIn, reserves)
});

// Execute swap
await contract.swap_a_for_b(amountIn, minAmountOut);
```

### 2. **Live Pool Visualization**
```typescript
// Get current state
const [reserveA, reserveB] = await contract.get_reserves();
const totalShares = await contract.get_total_shares();
const userShares = await contract.get_user_shares(userKey);

// Visualize pool
renderPool({
  reserveA,
  reserveB,
  ratio: reserveA / reserve B,
  userOwnership: (userShares / totalShares) * 100,
  tvl: calculateTVL(reserveA, reserveB)
});
```

### 3. **Transaction History Timeline**
```typescript
// Fetch events from contract
const swapCount = await contract.get_swap_count();
const recentSwaps = await fetchSwapEvents(swapCount - 10, swapCount);

// Render timeline
renderTimeline(recentSwaps.map(event => ({
  time: event.timestamp,
  type: 'swap',
  direction: event.direction,
  impact: calculateImpact(event)
})));
```

---

## 📈 **Advanced Features**

### Fee Tracking
- 0.3% fee on all swaps goes to liquidity providers
- LP shares represent proportional ownership of growing pool
- No separate fee claiming - fees auto-compound

### Slippage Protection
- `min_amount_out` parameter prevents sandwich attacks
- Calculate recommended slippage: `expected_out * (1 - slippage%)`

### First LP Lockup
- MIN_LIQUIDITY (1000 units) permanently locked on first add
- Prevents pool manipulation via dust amounts

---

## 🛡️ **Security Features**

1. ✅ No re-entrancy (Casper VM protection)
2. ✅ Integer overflow protection (U256 type)
3. ✅ Slippage protection on swaps
4. ✅ Minimum liquidity lockup
5. ✅ K-invariant verification

---

## 🎯 **Error Codes for UI Feedback**

| Code | Error | User Message |
|------|-------|--------------|
| 0 | InsufficientLiquidity | Not enough liquidity in pool |
| 1 | InsufficientAmount | Amount too small |
| 2 | InsufficientInputAmount | Input amount is zero |
| 3 | InsufficientOutputAmount | Output amount too small |
| 4 | InvalidK | Pool invariant violated (critical) |
| 5 | SlippageExceeded | Price moved unfavorably - try again |
| 6 | ZeroAmount | Cannot process zero amount |
| 7 | InvalidTokenAddress | Token address invalid |
| 8 | PoolNotInitialized | Pool not set up yet |
| 9 | AlreadyInitialized | Pool already initialized |

---

## 🎬 **Example User Journey**

1. **User visits StorySwap**
   - Animated pool visualization shows reserves bubbling
   - Live price ticker updates

2. **User enters swap amount**
   - Real-time quote animates calculation
   - Price impact meter fills up
   - Slippage warning appears if >1%

3. **User executes swap**
   - Token flows from wallet → pool (animated)
   - Reserve balances shift visually
   - Output token flows pool → wallet
   - Success confirmation with stats

4. **Pool updates**
   - New transaction appears in history timeline
   - Pool chart updates with new ratio point
   - Swap counter increments with celebration effect

---

## 📦 **File Structure**
```
amm_contract/
├── Cargo.toml          # Dependencies
├── Makefile            # Build automation
├── rust-toolchain      # Rust version pinning
└── src/
    ├── lib.rs          # Core AMM logic
    └── main.rs         # Entry points & installation
```

---

## 💰 **Gas Estimates**

| Operation | Estimated Gas (CSPR) |
|-----------|---------------------|
| Deploy | 200 CSPR |
| Initialize | 5 CSPR |
| Add Liquidity | 8-10 CSPR |
| Remove Liquidity | 8-10 CS PR |
| Swap | 5-7 CSPR |
| Query (read-only) | FREE |

---

**Built for storytelling. Designed for impact. Optimized for visuals.** 🚀
