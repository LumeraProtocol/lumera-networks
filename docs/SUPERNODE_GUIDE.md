# Lumera SuperNode Operator Guide

## Introduction

This guide provides comprehensive instructions for validator operators who wish to deploy and manage a SuperNode on the Lumera Protocol **mainnet**. SuperNodes provide additional services (storage, AI processing, and other network services) alongside standard block validation and earn **Proof-of-Service (PoSe)** rewards in parallel with PoS staking rewards.

> **Important:** Each validator may attach **exactly one** SuperNode. Your validator must already be running and have at least 25,000 LUME staked.

---

## Pre-flight Checklist

Gather the following information before starting:

- [ ] Validator mnemonic (if reusing validator key for SuperNode)
- [ ] SuperNode host public IP address
- [ ] Access to validator host (for registration commands)

---

## Step 1: Prerequisites

### System Requirements

Ensure your SuperNode host meets the following minimum requirements:

| Component | Minimum | Recommended | Notes |
|-----------|---------|-------------|-------|
| **CPU** | 8 × vCPU | 16 × vCPU | x86_64 architecture |
| **RAM** | 16 GB | 64 GB | For service processing |
| **Storage** | 1 TB NVMe | 4 TB NVMe | High-speed storage required |
| **Network** | 1 Gbps | 5 Gbps | Stable internet connection |
| **OS** | Ubuntu 22.04 LTS+ | Ubuntu 22.04 LTS+ | Install `build-essential` |

### Network Requirements

Your SuperNode host must have the following ports open:
- **Port 4444** (gRPC/API) - Inbound access required
- **Port 4445** (P2P) - Inbound access required (**Do not change this port**)

### Validator Prerequisites

Before proceeding, ensure:
- ✅ Your validator is running and operational
- ✅ Your validator has **≥ 25,000 LUME** self-staked
- ✅ You have access to your validator signing keys
- ✅ Your validator is either in the active set OR meets the 25,000 LUME requirement

> **Note:** The SuperNode and validator can (and should) run on separate servers for enhanced security and better performance under load.

---

## Step 2: Validator Stake Verification

**Host:** Validator Host

Verify that your validator meets the minimum staking requirements before proceeding with SuperNode installation.

### Check Current Validator Stake

```bash
# Get your validator operator address
# REPLACE 'validator_key' with your actual validator key name
VALOPER=$(lumerad keys show YOUR_VALIDATOR_KEY --bech val -a)
echo "Validator Address: $VALOPER"

# Check current validator status and stake
lumerad q staking validator $VALOPER
```

**Verify Requirements:**
- Look for the `tokens` field in the output
- Ensure it shows ≥ `25000000000000` (25,000 LUME in ulume)
- Confirm `status: BOND_STATUS_BONDED` if validator is active

> **Note:** If commands fail, add `--keyring-backend <backend>` flag matching your validator's keyring configuration.

### Add Additional Stake (if required)

If your validator requires additional stake:

```bash
# Check account balance for transaction fees
# REPLACE 'YOUR_VALIDATOR_KEY' with your actual validator key name
ACCOUNT_ADDR=$(lumerad keys show YOUR_VALIDATOR_KEY -a)
lumerad q bank balances $ACCOUNT_ADDR

# Delegate additional stake to reach 25,000 LUME requirement
# Example: Adding 20,000 LUME (20000000000000ulume)
lumerad tx staking delegate $VALOPER 20000000000000ulume \
  --from YOUR_VALIDATOR_KEY \
  --chain-id lumera-mainnet-1 \
  --gas auto --fees 5000ulume
```

### Verification
```bash
# Confirm updated stake
lumerad q staking validator $VALOPER | grep -E "tokens|operator_address"

# Verify you're on the correct chain
lumerad status | grep -E "network|chain_id"
# Should show: "network": "lumera-mainnet-1"
```

---

## Step 3: Install SuperNode Binary

**Host:** SuperNode Host

Download and install the latest SuperNode binary on your designated SuperNode host:

```bash
# Download the SuperNode binary
sudo curl -L \
  -o /usr/local/bin/supernode \
  https://github.com/LumeraProtocol/supernode/releases/latest/download/supernode-linux-amd64

# Make it executable
sudo chmod +x /usr/local/bin/supernode

# Verify installation
supernode version
```

### Verification
```bash
# Confirm binary is working
supernode version
# Should display version information

# Alternative check if version command fails
supernode --help
# Should display command help
```

---

## Step 4: Initialize SuperNode Configuration

**Host:** SuperNode Host

### Setup Configuration Directory

Create the SuperNode configuration directory and set proper permissions:

```bash
# Create SuperNode home directory
mkdir -p ~/.supernode
sudo chown $USER ~/.supernode -R
```

### Create Configuration File

Create the SuperNode configuration file at `~/.supernode/config.yml`:

```yaml
supernode:
  key_name: mykey
  identity: ""                   # Will be populated after key creation
  ip_address: 0.0.0.0           # Your server's public IP or 0.0.0.0
  port: 4444                    # gRPC/API port

keyring:
  backend: file                 # Options: file|os|test
  dir: keys                     # Directory for key storage

p2p:
  listen_address: 0.0.0.0
  port: 4445                    # DO NOT CHANGE - Required for P2P communication
  data_dir: data/p2p
  bootstrap_nodes: ""
  external_ip: ""               # Leave blank for auto-detection

lumera:
  grpc_addr: "grpc.lumera.io:443"    # Public endpoint (no local node required)
  chain_id: "lumera-mainnet-1"

raptorq:
  files_dir: raptorq_files
```

> **Network Options:** You can point `lumera.grpc_addr` to either a local full node (`localhost:9090`) or use the public endpoint. The public endpoint is recommended for simplicity.

### Verification
```bash
# Check configuration file exists and is readable
cat ~/.supernode/config.yml
# Should display the configuration content
```

---

## Step 5: SuperNode Key Management

**Host:** SuperNode Host

### What are SuperNode Keys

SuperNode keys are used to sign transactions for proof of service after completing tasks. The account needs funds for gas fees. Example address: `lumera1ccmw5plzuldntum2rz6kq6uq346vtrhrvwfzsa`

### Add Keys

Choose one of the following approaches:

#### Option A: Use Existing Key (Recommended)

Use your validator mnemonic or any existing key mnemonic to recover the key:

```bash
supernode keys recover mykey --mnemonic "hope bulk clever tip road female fly quiz once dose journey sting hedgehog pull area envelope supreme maze project spike brave shed fish live" -c ~/.supernode/config.yml
```

**Expected Output:**
```
Key recovered successfully!
- Name: mykey
- Address: lumera1ae37km54w88f783cktmpyd3fny0ycdn69ftt6e
```

#### Option B: Create Brand New Key

Generate a completely new key:

```bash
supernode keys add mykey -c ~/.supernode/config.yml
```

**Expected Output:**
```
Key generated successfully!
- Name: mykey
- Address: lumera1uadeldc7vt4mnrxucgq007v74l6uw65n8uhyd9
- Mnemonic: donkey dry over patch boy dance oven wrist clock sea prison deer carbon uncover various chase solution leave battle glide polar suspect trade bunker
```

> **Important:** When adding a new key, you will have to add funds to it for gas and transaction fees.

> **Note:** When using keyring backends other than `test` (such as `file` or `os`), you will be prompted to set a keyring password for additional security.

### Update Configuration

After adding your key, update your `~/.supernode/config.yml` with the key information:

```yaml
supernode:
  key_name: "mykey"              # Must match the key name you just created
  identity: "lumera1ae37km54w88f783cktmpyd3fny0ycdn69ftt6e"   # Paste the address from the add or recover command
```

> **Security:** Store your mnemonic phrase and keyring password securely. These are required for key recovery.

---

## Step 5: Validator Stake Verification

**Host:** Validator Host

Verify that your validator meets the minimum staking requirements before registration.

### Check Current Validator Stake

```bash
# Get your validator operator address
VALOPER=$(lumerad keys show <your_validator_key> --bech val -a)
echo "Validator Address: $VALOPER"

# Check current validator status and stake
lumerad q staking validator $VALOPER
```

**Verify Requirements:**
- Look for the `tokens` field in the output
- Ensure it shows ≥ `25000000000000` (25,000 LUME in ulume)
- Confirm `status: BOND_STATUS_BONDED` if validator is active

> **Note:** If commands fail, add `--keyring-backend <backend>` flag matching your validator's keyring configuration.

### Add Additional Stake (if required)

If your validator requires additional stake:

```bash
# Check account balance for transaction fees
ACCOUNT_ADDR=$(lumerad keys show <your_validator_key> -a)
lumerad q bank balances $ACCOUNT_ADDR

# Delegate additional stake to reach 25,000 LUME requirement
# Example: Adding 20,000 LUME (20000000000000ulume)
lumerad tx staking delegate $VALOPER 20000000000000ulume \
  --from <your_validator_key> \
  --chain-id lumera-mainnet-1 \
  --gas auto --fees 5000ulume
```

### Verify Delegation

```bash
# Confirm updated stake
lumerad q staking validator $VALOPER | grep -E "tokens|operator_address"
```

---

## Step 6: SuperNode Service Deployment

**Host:** SuperNode Host

### Create Systemd Service

Create a systemd service file for automatic SuperNode management:

**Option A: Using absolute path (recommended)**
```bash
sudo tee /etc/systemd/system/supernode.service <<EOF
[Unit]
Description=Lumera SuperNode
After=network-online.target

[Service]
User=$USER
ExecStart=/usr/local/bin/supernode start -c $HOME/.supernode/config.yml
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
```

**Option B: Alternative if Option A fails**
```bash
# Get your username and home directory
USERNAME=$(whoami)
HOMEDIR=$HOME

sudo tee /etc/systemd/system/supernode.service <<EOF
[Unit]
Description=Lumera SuperNode
After=network-online.target

[Service]
User=$USERNAME
ExecStart=/usr/local/bin/supernode start -c $HOMEDIR/.supernode/config.yml
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
```

### Start SuperNode Service

```bash
# Reload systemd configuration
sudo systemctl daemon-reload

# Enable and start SuperNode service
sudo systemctl enable --now supernode

# Monitor service logs
journalctl -u supernode -f
```

### Verification
```bash
# Check service status
sudo systemctl status supernode
# Should show "active (running)" status

# Check recent logs
journalctl -u supernode --since "5 minutes ago"
# Should show initialization and connection logs
```

**Expected Behavior:**
- Initial connection and synchronization logs
- P2P network discovery
- Transition to `state=ACTIVE` status

---

## Step 7: SuperNode Registration

**Host:** Validator Host

Register your SuperNode with the Lumera network. This step must be executed from your **validator host** where the validator signing keys are stored, **after** your SuperNode service is running.

### Execute Registration Transaction

First, get your validator operator address and SuperNode account information:

```bash
# Get your validator operator address
VALOPER=$(lumerad keys show <your_validator_key> --bech val -a)
echo "Validator Operator Address: $VALOPER"
# Example output: lumeravaloper1ysskfqgcvap67tc8khxu4yrv99g6lhf7whyfwv

# Use the SuperNode account from your config.yml
SUPERNODE_ACCOUNT="lumera1ccmw5plzuldntum2rz6kq6uq346vtrhrvwfzsa"  # Your configured identity
```

Register the SuperNode on-chain:

```bash
lumerad tx supernode register-supernode \
  $VALOPER \
  192.168.1.100:4444 \
  $SUPERNODE_ACCOUNT \
  --from <your_validator_key> \
  --chain-id lumera-mainnet-1 \
  --gas auto --fees 5000ulume
```

**Parameters:**
- `$VALOPER`: Your validator operator address (e.g., `lumeravaloper1ysskfqgcvap67tc8khxu4yrv99g6lhf7whyfwv`)
- `192.168.1.100:4444`: Your SuperNode's gRPC endpoint (replace with your actual public IP and port)
- `$SUPERNODE_ACCOUNT`: The SuperNode account address from Step 4 (e.g., `lumera1ccmw5plzuldntum2rz6kq6uq346vtrhrvwfzsa`)
- `<your_validator_key>`: Your validator key name for signing

**Validation:** The transaction will verify:
- Signature authenticity from validator operator
- Minimum 25,000 LUME self-bond requirement (for non-active validators)

---

## Step 7: SuperNode Service Deployment

**Host:** SuperNode Host

### Create Systemd Service

Create a systemd service file for automatic SuperNode management:

```bash
sudo tee /etc/systemd/system/supernode.service <<EOF
[Unit]
Description=Lumera SuperNode
After=network-online.target

[Service]
User=$(whoami)
ExecStart=/usr/local/bin/supernode start -c /home/$(whoami)/.supernode/config.yml
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
```

### Start SuperNode Service

```bash
# Reload systemd configuration
sudo systemctl daemon-reload

# Enable and start SuperNode service
sudo systemctl enable --now supernode

# Monitor service logs
journalctl -u supernode -f
```

**Expected Behavior:**
- Initial connection and synchronization logs
- P2P network discovery
- Transition to `state=ACTIVE` status

---

## Step 8: Verification and Monitoring

### Verify SuperNode Status

**Host:** Validator Host

Check your SuperNode registration and operational status:

```bash
# Query SuperNode status
lumerad q supernode get-super-node $VALOPER \
  --node https://rpc.lumera.io:443
```

You should find the latest state set to `ACTIVE`.

### Monitor SuperNode Operations

**Host:** SuperNode Host

```bash
# Monitor real-time logs
journalctl -u supernode -f

# Check service status
sudo systemctl status supernode

# View recent logs
journalctl -u supernode --since "1 hour ago"
```

---

## Step 9: SuperNode Operations Management

### Common Management Commands

| Operation | Command | Purpose | Host |
|-----------|---------|---------|------|
| **Status Check** | `lumerad q supernode get-super-node <validator-address>` | Verify SuperNode status | Validator Host |
| **Stop SuperNode** | `lumerad tx supernode stop-supernode <validator-address> "<reason>" --from <key>` | Gracefully stop SuperNode | Validator Host |
| **Start SuperNode** | `lumerad tx supernode start-supernode <validator-address> --from <key>` | Restart stopped SuperNode | Validator Host |
| **Update SuperNode** | `lumerad tx supernode update-supernode <validator-address> <ip> <version> <account> --from <key>` | Update SuperNode configuration | Validator Host |
| **Deregister** | `lumerad tx supernode deregister-supernode <validator-address> --from <key>` | Permanently remove SuperNode | Validator Host |

### Important Operational Notes

**Configuration Requirements:**
- Your `key_name` in config must match the name used with `supernode keys add`
- Your `identity` in config must match the address generated for your key
- The P2P port (4445) should never be changed from the default
- Ensure your validator node is accessible at the configured `grpc_addr`

**Planned Maintenance:**

**Host:** Validator Host
```bash
# Always stop SuperNode on-chain before maintenance
lumerad tx supernode stop-supernode $VALOPER "planned maintenance" --from validator_key
```

**Emergency Shutdown:**

**Host:** Validator Host
```bash
# If SuperNode goes offline unexpectedly, notify the network
lumerad tx supernode stop-supernode $VALOPER "unexpected downtime" --from validator_key
```

> **Critical:** Keeping chain state synchronized prevents penalties and maintains network integrity.

---

## Step 10: Security Best Practices

### Infrastructure Security

- **🏠 Separate Hosting**: Deploy SuperNode on a different server than validator signing keys
- **🔥 Network Security**: Implement firewall rules allowing only ports 4444 and 4445
- **🔐 Key Management**: Use secure keyring backends (`os` or HSM) for production environments

### Operational Security

**Host:** SuperNode Host

```bash
# Use secure keyring backend for production
keyring:
  backend: os  # or hardware security module (HSM)

# Monitor SuperNode health
journalctl -u supernode -f

# Regular security updates
sudo apt update && sudo apt upgrade
```

### Backup Requirements
**Critical Files and Folders to Backup:**
- The entire `~/.supernode/` folder (includes `config.yml`, keyring files, and all related data)

> **Tip:** Regularly back up the full `~/.supernode/` directory to ensure you can recover configuration, keys, and operational state in case of hardware failure or migration.

## Configuration Reference

### Detailed Configuration Parameters

| Parameter | Description | Required | Default | Example | Notes |
|-----------|-------------|----------|---------|---------|--------|
| `supernode.key_name` | Name of the key for signing transactions | **Yes** | - | `"mykey"` | Must match the name used with `supernode keys add` |
| `supernode.identity` | Lumera address for this supernode | **Yes** | - | `"lumera1ccmw5plzuldntum2rz6kq6uq346vtrhrvwfzsa"` | Obtained after creating/recovering a key |
| `supernode.ip_address` | IP address to bind the supernode service | **Yes** | - | `"0.0.0.0"` | Use `"0.0.0.0"` to listen on all interfaces |
| `supernode.port` | Port for the supernode service | **Yes** | - | `4444` | Choose an available port |
| `keyring.backend` | Key storage backend type | **Yes** | - | `"file"` | `"test"` for development, `"file"` for encrypted storage, `"os"` for OS keyring |
| `keyring.dir` | Directory to store keyring files | No | `"keys"` | `"keys"` | Relative paths are appended to basedir, absolute paths used as-is |
| `p2p.listen_address` | IP address for P2P networking | **Yes** | - | `"0.0.0.0"` | Use `"0.0.0.0"` to listen on all interfaces |
| `p2p.port` | P2P communication port | **Yes** | - | `4445` | **Do not change this default value** |
| `p2p.data_dir` | Directory for P2P data storage | No | `"data/p2p"` | `"data/p2p"` | Relative paths are appended to basedir, absolute paths used as-is |
| `p2p.bootstrap_nodes` | Initial peer nodes for network discovery | No | `""` | `""` | Comma-separated list of peer addresses, leave empty for auto-discovery |
| `p2p.external_ip` | Your public IP address | No | `""` | `""` | Leave empty for auto-detection, or specify your public IP |
| `lumera.grpc_addr` | gRPC endpoint of Lumera validator node | **Yes** | - | `"grpc.lumera.io:443"` | Must be accessible from supernode |
| `lumera.chain_id` | Lumera blockchain chain identifier | **Yes** | - | `"lumera-mainnet-1"` | Must match the actual chain ID |
| `raptorq.files_dir` | Directory to store RaptorQ files | No | `"raptorq_files"` | `"raptorq_files"` | Relative paths are appended to basedir, absolute paths used as-is |

---

## Troubleshooting

### Common Issues and Solutions

| Issue | Symptom | Solution | Host |
|-------|---------|----------|------|
| **Registration Failure** | `insufficient funds` error | Ensure validator account has LUME for transaction fees | Validator Host |
| **Connection Issues** | SuperNode not reaching `ACTIVE` state | Verify ports 4444 and 4445 are open and accessible | SuperNode Host |
| **Key Errors** | Authentication failures | Add `--keyring-backend <type>` to commands | Validator Host |
| **Sync Issues** | SuperNode stuck in startup | Check `grpc_addr` connectivity and network access | SuperNode Host |

### Service Management

**Host:** SuperNode Host

```bash
# Restart SuperNode service
sudo systemctl restart supernode

# View detailed logs
journalctl -u supernode --no-pager

# Check configuration validity
supernode config validate -c ~/.supernode/config.yml
```

### Network Verification

**Host:** SuperNode Host

```bash
# Test connectivity to gRPC endpoint
telnet grpc.lumera.io 443

# Verify local port accessibility
netstat -tlnp | grep -E "4444|4445"
```

---

## Important Notes

### Requirements Compliance
- Maintain minimum 25,000 LUME validator stake
- Ensure consistent SuperNode uptime (>95% recommended)
- Keep SuperNode software updated with latest releases
- Respond to network governance proposals affecting SuperNode operations

### Communication Channels
- **Technical Support**: [Discord](https://discord.com/channels/774465063540097050/1341907501427331153)
- **Network Updates**: [Discord](https://discord.com/channels/774465063540097050/1341907672668176394)
- **Documentation**: [GitHub Repository](https://github.com/LumeraProtocol/lumera-networks)

---

## Quick Reference

**SuperNode Host:**
```bash
# 1. Install binary
sudo curl -L -o /usr/local/bin/supernode \
  https://github.com/LumeraProtocol/supernode/releases/latest/download/supernode-linux-amd64 && \
sudo chmod +x /usr/local/bin/supernode

# 2. Create config.yml with grpc_addr: "grpc.lumera.io:443"
mkdir -p ~/.supernode

# 3. Generate keys and update identity in config
supernode keys add mykey -c ~/.supernode/config.yml

# 4. Deploy service
sudo systemctl enable --now supernode
```

**Validator Host:**
```bash
# 5. Verify validator stake (25,000+ LUME)
VALOPER=$(lumerad keys show validator_key --bech val -a)
lumerad q staking validator $VALOPER

# 6. Register SuperNode (after SuperNode is running)
# IMPORTANT: Replace these variables with your actual values
SUPERNODE_ACCOUNT="lumera1ae37km54w88f783cktmpyd3fny0ycdn69ftt6e"  # YOUR identity from config.yml
SUPERNODE_ENDPOINT="203.0.113.1:4444"  # YOUR public IP:4444

lumerad tx supernode register-supernode $VALOPER $SUPERNODE_ENDPOINT $SUPERNODE_ACCOUNT --from validator_key

# 7. Verify activation
lumerad q supernode get-super-node $VALOPER
```

**Success Indicator:** `"state": "ACTIVE"` → Earning PoSe rewards

---

*Lumera Protocol SuperNode Operations Guide v1.1*
*For additional support, consult the validator documentation or reach out via official channels.*