# Lumera Testnet-2 Validator Setup Log

## Prerequisites
- `lumerad` v1.6.1 binary installed at `/usr/local/bin/lumerad`
- Required files available in `/home/enxsys/Documents/Github/lumera-networks/testnet-2/`

## Setup Steps Completed

### 1. Node Initialization
```bash
lumerad init cosmic-hodler --chain-id lumera-testnet-2
```
- **Moniker**: cosmic-hodler
- **Chain ID**: lumera-testnet-2
- **Node ID**: 1059d0c07bae1348fe86ab63a4b754f783509241
- **Config Directory**: `~/.lumera/config/`

### 2. Network Files Configuration
```bash
# Copy genesis file
cp /home/enxsys/Documents/Github/lumera-networks/testnet-2/genesis.json ~/.lumera/config/

# Copy claims file
cp /home/enxsys/Documents/Github/lumera-networks/testnet-2/claims.csv ~/.lumera/config/
```

### 3. Node Configuration
**File**: `~/.lumera/config/app.toml`
```toml
minimum-gas-prices = "0.025ulume"
```

**File**: `~/.lumera/config/config.toml`
```toml
seeds = "faff7c1350468c53121a669ac40e317a4a70c425@seeds.lumera.io:26656"
```

## Network Details
- **Chain ID**: lumera-testnet-2
- **Gas Price**: 0.025ulume
- **Seed Node**: faff7c1350468c53121a669ac40e317a4a70c425@seeds.lumera.io:26656
- **Explorer**: https://portal.testnet.lumera.io/lumera-testnet-2


# Lumera Testnet-2 Validator Setup Summary

## ✅ Completed Setup
- **Node initialized**: cosmic-hodler on lumera-testnet-2
- **Node ID**: 1059d0c07bae1348fe86ab63a4b754f783509241
- **Wallet created**: "matee" key with 2 LUME balance
- **Account address**: lumera1tzghn5e697kpu7lyq37qsvmjtecs8lap5fg8vp
- **Validator address**: lumeravaloper1tzghn5e697kpu7lyq37qsvmjtecs8lap5fg8vp
- **Validator pubkey**: `{"@type":"/cosmos.crypto.ed25519.PubKey","key":"IfuvzD/20UKDZZc2aRoK0Uwt4S0+dETL5scsodGWjHg="}`

## 🎯 Goal: Become Validator
**Strategy**: Self-delegate 1 LUME (1,000,000 ulume), keep 1 LUME for fees

## 📋 Validator Parameters
- **Moniker**: cosmic-hodler
- **Commission**: 5% (competitive with other validators)
- **Max commission**: 20%
- **Min self-delegation**: 1,000,000 ulume

## 🔧 Ready-to-Execute Commands
```bash
# 1. Create validator.json (already done)
# 2. Dry run test
lumerad tx staking create-validator validator.json --chain-id=lumera-testnet-2 --gas="auto" --gas-adjustment="1.2" --gas-prices="0.025ulume" --from=matee --dry-run

# 3. Create validator
lumerad tx staking create-validator validator.json --chain-id=lumera-testnet-2 --gas="auto" --gas-adjustment="1.2" --gas-prices="0.025ulume" --from=matee
```

## 📊 Current Network Context
- **Top validators**: ~50,001 LUME voting power
- **Common commissions**: 5-20%

## ✅ Validator Creation Completed
**Transaction Hash**: `4869946545398E1D017E0621F2262C46E6CAB2C5A73CD9CF47C95290B3413D5F`
- **Gas Used**: 205,452
- **Fee Paid**: 5,137 ulume (0.005137 LUME)
- **Status**: Success (code: 0)
- **Block Height**: 212340

## 📊 Current Validator Status
- **Moniker**: cosmic-hodler
- **Operator Address**: lumeravaloper1tzghn5e697kpu7lyq37qsvmjtecs8lap5fg8vp
- **Tokens**: 1,000,000 ulume (1 LUME self-delegation)
- **Commission**: 5%
- **Status**: BOND_STATUS_UNBONDED
- **Remaining Balance**: 994,863 ulume (~0.995 LUME)

## Working Commands Reference

### Validator Creation
```bash
lumerad tx staking create-validator validator.json --chain-id=lumera-testnet-2 --gas="auto" --gas-adjustment="1.2" --gas-prices="0.025ulume" --from=matee
```

### Delegation (Correct Working Command)
```bash
lumerad tx staking delegate lumeravaloper1tzghn5e697kpu7lyq37qsvmjtecs8lap5fg8vp 8020000ulume --from matee --chain-id lumera-testnet-2 --gas="auto" --gas-adjustment="1.2" --gas-prices="0.025ulume"
```

### Query Commands
```bash
# Check balance
lumerad query bank balances lumera1tzghn5e697kpu7lyq37qsvmjtecs8lapmnmm2z

# Check validator status
lumerad query staking validator lumeravaloper1tzghn5e697kpu7lyq37qsvmjtecs8lap5fg8vp

# Check staking parameters
lumerad query staking params

# Check active validators
lumerad query staking validators --status bonded
```

### Key Learnings
- Always use `--gas-adjustment="1.2"` with auto gas for safety
- Network has max 50 active validators
- Need to be in top 50 by stake to become active
- Your validator has 1,980,000 ulume total stake and is properly configured