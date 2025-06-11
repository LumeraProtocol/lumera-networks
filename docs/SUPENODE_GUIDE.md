# Lumera Supernode

Lumera Supernode is a companion application for Lumera validators who want to provide cascade, sense, and other services to earn rewards.


## Hardware Requirements

### Minimum Hardware Requirements

- **CPU**: 8 cores, x86_64 architecture
- **RAM**: 16 GB RAM
- **Storage**: 1 TB NVMe SSD
- **Network**: 1 Gbps
- **Operating System**: Ubuntu 22.04 LTS or higher

### Recommended Hardware Requirements

- **CPU**: 16 cores, x86_64 architecture
- **RAM**: 64 GB RAM
- **Storage**: 4 TB NVMe SSD
- **Network**: 5 Gbps
- **Operating System**: Ubuntu 22.04 LTS or higher

## Prerequisites

Before installing and running the Lumera Supernode, ensure you have the following prerequisites installed:

### Install Build Essentials

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install build-essential

# CentOS/RHEL/Fedora
sudo yum groupinstall "Development Tools"
# or for newer versions
sudo dnf groupinstall "Development Tools"
```

### Enable CGO

CGO must be enabled for the supernode to compile and run properly. Set the environment variable:

```bash
export CGO_ENABLED=1
```

To make this permanent, add it to your shell profile:

```bash
echo 'export CGO_ENABLED=1' >> ~/.bashrc
source ~/.bashrc
```

## Installation

### 1. Download the Binary

Download the latest release from GitHub:


### 2. Create Configuration File

Create a `config.yml` file in the same directory as your binary 

```yaml
# Supernode Configuration
supernode:
  key_name: "mykey"  # The name you'll use when creating your key
  identity: ""       # The address you get back after getting the key
  ip_address: "0.0.0.0"
  port: 4444

# Keyring Configuration
keyring:
  backend: "test"  # Options: test, file, os
  dir: "keys"

# P2P Network Configuration
p2p:
  listen_address: "0.0.0.0"
  port: 4445
  data_dir: "data/p2p"
  bootstrap_nodes: ""
  external_ip: ""

# Lumera Chain Configuration
lumera:
  grpc_addr: "localhost:9090"
  chain_id: "lumera"

# RaptorQ Configuration
raptorq:
  files_dir: "raptorq_files"
```

## Key Management

### Create a New Key

Create a new key (use the same name you specified in your config):

```bash
supernode keys add mykey
```

This will output an address like:
```
lumera15t2e8gjgmuqtj4jzjqfkf3tf5l8vqw69hmrzmr
```

### Recover an Existing Key

If you have an existing mnemonic phrase:

```bash
supernode keys recover mykey <MNEMONIC>
```

### List Keys

```bash
supernode keys list
```

### Update Configuration with Your Address

⚠️ **IMPORTANT:** After generating or recovering a key, you MUST update your `config.yml` with the generated address:

```yaml
supernode:
  key_name: "mykey"
  identity: "lumera15t2e8gjgmuqtj4jzjqfkf3tf5l8vqw69hmrzmr"  # Your actual address
  ip_address: "0.0.0.0"
  port: 4444
# ... rest of config
```

## Running the Supernode

### Start the Supernode

```bash
supernode start
```

### Using Custom Configuration

```bash
# Use specific config file
supernode start -c /path/to/config.yml

# Use custom base directory
supernode start -d /path/to/basedir
```

## Configuration Parameters

| Parameter | Description | Required | Default | Example | Notes |
|-----------|-------------|----------|---------|---------|--------|
| `supernode.key_name` | Name of the key for signing transactions | **Yes** | - | `"mykey"` | Must match the name used with `supernode keys add` |
| `supernode.identity` | Lumera address for this supernode | **Yes** | - | `"lumera15t2e8gjgmuqtj4jzjqfkf3tf5l8vqw69hmrzmr"` | Obtained after creating/recovering a key |
| `supernode.ip_address` | IP address to bind the supernode service | **Yes** | - | `"0.0.0.0"` | Use `"0.0.0.0"` to listen on all interfaces |
| `supernode.port` | Port for the supernode service | **Yes** | - | `4444` | Choose an available port |
| `keyring.backend` | Key storage backend type | **Yes** | - | `"test"` | `"test"` for development, `"file"` for encrypted storage, `"os"` for OS keyring |
| `keyring.dir` | Directory to store keyring files | No | `"keys"` | `"keys"` | Relative paths are appended to basedir, absolute paths used as-is |
| `p2p.listen_address` | IP address for P2P networking | **Yes** | - | `"0.0.0.0"` | Use `"0.0.0.0"` to listen on all interfaces |
| `p2p.port` | P2P communication port | **Yes** | - | `4445` | **Do not change this default value** |
| `p2p.data_dir` | Directory for P2P data storage | No | `"data/p2p"` | `"data/p2p"` | Relative paths are appended to basedir, absolute paths used as-is |
| `p2p.bootstrap_nodes` | Initial peer nodes for network discovery | No | `""` | `""` | Comma-separated list of peer addresses, leave empty for auto-discovery |
| `p2p.external_ip` | Your public IP address | No | `""` | `""` | Leave empty for auto-detection, or specify your public IP |
| `lumera.grpc_addr` | gRPC endpoint of Lumera validator node | **Yes** | - | `"localhost:9090"` | Must be accessible from supernode |
| `lumera.chain_id` | Lumera blockchain chain identifier | **Yes** | - | `"lumera"` | Must match the actual chain ID |
| `raptorq.files_dir` | Directory to store RaptorQ files | No | `"raptorq_files"` | `"raptorq_files"` | Relative paths are appended to basedir, absolute paths used as-is |

## Command Line Flags

The supernode binary supports the following command-line flags:

| Flag | Short | Description | Value Type | Example | Default |
|------|-------|-------------|------------|---------|---------|
| `--config` | `-c` | Path to configuration file | String | `-c /path/to/config.yml` | `config.yml` in current directory |
| `--basedir` | `-d` | Base directory for data storage | String | `-d /custom/path` | `~/.supernode` |

### Usage Examples

```bash
# Use default config.yml in current directory
supernode start

# Use custom config file
supernode start -c /etc/supernode/config.yml
supernode start --config /etc/supernode/config.yml

# Use custom base directory
supernode start -d /opt/supernode
supernode start --basedir /opt/supernode

# Combine flags
supernode start -c /etc/supernode/config.yml -d /opt/supernode
```

## Important Notes

⚠️ **CRITICAL: Consistent Flag Usage Across Commands**

If you use custom flags (`--config` or `--basedir`) for key management operations, you **MUST** use the same flags for ALL subsequent commands, including the `start` command. Otherwise, your configuration will break and keys will not be found.

### Examples of Correct Flag Usage:

**Scenario 1: Using custom config file**
```bash
# Create key with custom config
supernode keys add mykey -c /etc/supernode/config.yml

# Start supernode with same config
supernode start -c /etc/supernode/config.yml
```

**Scenario 2: Using custom base directory**
```bash
# Create key with custom basedir
supernode keys add mykey -d /opt/supernode

# Recover key with same basedir
supernode keys recover mykey "your mnemonic phrase here" -d /opt/supernode

# Start supernode with same basedir
supernode start -d /opt/supernode
```

**Scenario 3: Using both custom config and basedir**
```bash
# Create key with both flags
supernode keys add mykey -c /etc/supernode/config.yml -d /opt/supernode

# Start supernode with both flags
supernode start -c /etc/supernode/config.yml -d /opt/supernode
```

**❌ WRONG - This will cause configuration breakage:**
```bash
# Create key with custom basedir
supernode keys add mykey -d /opt/supernode

# Start without the same basedir flag - keys won't be found!
supernode start
```

### Additional Important Notes:

- Make sure you have sufficient balance in your Lumera account to broadcast transactions
- The P2P port (4445) should not be changed from the default
- Your `key_name` in the config must match the name you used when creating the key
- Your `identity` in the config must match the address generated for your key
- Ensure your Lumera validator node is running and accessible at the configured gRPC address

## Troubleshooting

### Key Not Found
Make sure the `key_name` in your config matches the name you used with `supernode keys add`. Also ensure you're using the same `--config` and `--basedir` flags across all commands.

### Address Mismatch
Ensure the `identity` field in your config matches the address returned when you created your key.

### Connection Issues
Verify that your Lumera validator node is running and accessible at the configured `grpc_addr`.

### Insufficient Balance
Check that your account has sufficient LUMERA tokens to pay for transaction fees.

### Configuration Break
If your configuration seems broken, verify that you're using consistent command-line flags (`--config` and `--basedir`) across all supernode commands.

## Support

For issues and support, please refer to the Lumera Protocol documentation or community channels.