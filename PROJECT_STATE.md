# 📊 Bastion DeFi Platform - Production TUI Edition

## 🎯 Project Overview

**Name:** Bastion Dark Pool - ZK-Powered Anti-MEV DEX  
**Network:** Casper Testnet (`casper-test`)  
**Interface:** Production CLI with gum TUI  
**Status:** 🟢 FULLY OPERATIONAL

---

## ✅ Deployed Smart Contracts

| Contract | Hash |
|----------|------|
| **BastionUSD Token** | `hash-64d47b728ae3ea2b147bc4660cad93a56577ffd798e17e022056b85b3643d6b4` |
| **Simple AMM** | `hash-f6261e8cd55db234f7a6525b7cedaa53123b510aace8f0cf02bcf0dd25524636` |
| **Bastion Dark Pool** | `hash-9b1ee8aed8931f05cf8efd0eb92f1dab473f1b9c0a9c4c0b8b83ec38db0598c9` |

---

## 📁 Project Structure

```
bastion/
├── cli/                    # Production TUI Suite
│   ├── bastion             # Main entry point
│   ├── config/
│   │   └── contracts.env   # Contract configuration
│   └── lib/
│       ├── ui.sh           # UI components, banner, colors
│       ├── network.sh      # RPC calls, status checks
│       ├── identity.sh     # Multi-wallet management
│       ├── ledger.sh       # Transaction history
│       ├── zkproof.sh      # ZK proof simulation
│       ├── simulation.sh   # MEV attack demo
│       ├── whale.sh        # Iceberg orders
│       ├── ticker.sh       # Live market ticker
│       ├── arbitrage.sh    # Price scanner
│       └── liquidity.sh    # Liquidity management
│
├── amm_contract/           # AMM source code
├── bastion_contract/       # Dark Pool source code
├── cep18/                  # Token reference
├── keys/                   # Identity key files
│
├── bastion                 # Symlink to cli/bastion
├── COMPLETE_USER_GUIDE.md
├── PROJECT_STATE.md
├── secret_key.pem
└── .env
```

---

## 🚀 Quick Start

```bash
cd /home/starlord/Casper/bastion

# Launch interactive TUI
./bastion

# Or use specific commands
./bastion help      # Show all commands
./bastion demo      # Run MEV simulation
./bastion trade     # Quick trade
./bastion ticker    # Live prices
./bastion identity  # Manage wallets
./bastion history   # Transaction ledger
```

---

## 🎨 TUI Features

| Feature | Description |
|---------|-------------|
| **🔐 Quick Trade** | Submit orders to Bastion Dark Pool |
| **💧 Liquidity Center** | Add/remove liquidity with state diff |
| **👥 Identity Manager** | Hot-swap between user/whale/attacker |
| **📜 Transaction Ledger** | Search/filter past transactions |
| **📊 Live Ticker** | Real-time price updates (no flicker) |
| **📉 Arbitrage Scanner** | AMM vs Oracle price spreads |
| **🐳 Whale Mode** | Iceberg order execution |
| **⚔️ MEV Simulation** | Side-by-side attack demo |
| **🔬 ZK Proof Demo** | Visual proof generation |
| **⚙️ Settings** | View contracts, test connection |

---

## 🎯 Hackathon Demo Flow

1. **Launch** → `./bastion` → Show Rook banner
2. **Identity** → Switch to "whale" wallet
3. **Liquidity** → Add liquidity, show state diff
4. **Arbitrage** → Show price opportunities
5. **MEV Demo** → Sandwich attack vs Bastion protection
6. **ZK Proof** → Show proof generation pipeline
7. **Quick Trade** → Execute protected order
8. **Ledger** → Show transaction receipts

---

## 📊 Account Info

| Property | Value |
|----------|-------|
| **Account Hash** | `account-hash-9833bf9ef9c422aa2b481e212c9c4a40018c23d97909e846e6dde4640ab2e46b` |
| **Balance** | ~7,300 CSPR |
| **RPC** | `https://node.testnet.cspr.cloud/rpc` |

---

*Production TUI Suite - Last Updated: 2026-01-11*
