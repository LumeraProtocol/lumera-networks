# Lumera SuperNode Operator Guide

---

## 0) Quick mental model (non-technical)

A SuperNode is a service machine connected to your validator.

- **Validator**: on-chain identity; you sign the registration transaction from the validator host.
- **SuperNode host**: runs the SuperNode software and exposes network ports.
- **SuperNode Account (`SN_ACCOUNT`)**: a wallet address (`lumera1...`) used for LEP-3 stake validation.
It can be
  - your own wallet, or
  - a foundation-funded vesting wallet (temporary/permanent lock).

**Never run validator and SuperNode on the same server.**

---

## 1) Prerequisites

### 1.1 Validator prerequisites

- Validator is installed, configured, and running.
  - NOTE: The validator can be in the **bonded** or **unbondig**
- You control the validator operator key (`<val_key>`) on the validator host

### 1.2 SuperNode host requirements

Recommended baseline (adjust as the network evolves):

- Ubuntu 22.04+ (recommended)
- Enough CPU/RAM/NVMe for your expected workload

**Firewall / inbound ports on the SuperNode host**

- `4444/tcp` (SuperNode gRPC API)
- `8002/tcp` (REST Gateway)
- `4445/tcp` (P2P)

---

## 2) LEP-3 Dual-Source Stake

### 2.1 The old idea (before LEP-3)

To qualify for SuperNode registration, your **validator self-delegation** had to meet the minimum requirement by itself.

### 2.2 The new idea (LEP-3)

Eligibility can be met by combining:

1. **validator self-delegation** (must exist), plus
2. **delegation from a SuperNode Account (`SN_ACCOUNT`)** (optional, but often used)

**Key point:** the eligibility check still requires your validator to have **some self-delegation** (non-zero).

LEP-3 adds extra stake on top via `SN_ACCOUNT`.

### 2.3 Foundation-assisted stake (the correct flow)

The foundation does **not** delegate on your behalf.

Instead:

1. you provide a **fresh** `SN_ACCOUNT` address (`lumera1...`)
2. the foundation **sends funds** to it while creating a vesting account:
    - **temporarily locked (delayed vesting):** unlocks over time / after a delay
    - **permanently locked (permanent vesting):** never unlocks
3. **you** delegate from `SN_ACCOUNT` to your validator

Those delegated vesting funds count for **LEP-3 Dual-Source Stake**.

---

## 3) Choose your “stake + key” path (3 options)

All operators must choose one of these. They differ only by **where `SN_ACCOUNT` comes from** and **who funds it**.

### Option 1 — Self-stake only (simplest)

- You fund and delegate enough stake from your validator/self wallets
- `SN_ACCOUNT` can be a normal SuperNode key you create during setup (or any wallet you control)

### Option 2 — Foundation-funded `SN_ACCOUNT` (new key generated on the SuperNode host)

- You create a fresh key on the SuperNode host (becomes `SN_ACCOUNT`)
- Foundation funds it as vesting (temporary/permanent lock)
- You delegate from `SN_ACCOUNT` to your validator

### Option 3 — Foundation-funded `SN_ACCOUNT` (existing key you already created elsewhere)

- You create a fresh wallet key somewhere safe
- Foundation funds it as vesting
- You import/recover that key on the SuperNode host (or any machine you’ll use to delegate)
- You delegate from `SN_ACCOUNT` to your validator

---

## 4) Common values you will need (fill these once)

- `CHAIN_ID` (example: `lumera-testnet-2`)
- `VALOPER` = your validator operator address (`lumeravaloper...`)
- `SN_ENDPOINT` = `"<SN_PUBLIC_IP>:4444"`
- `SN_ACCOUNT` = SuperNode Account address (`lumera1...`)

Get `VALOPER` on the **validator host**:

```bash
VALOPER=$(lumerad keys show <val_key> --bech val -a)
echo "$VALOPER"
```

---

## Part A — Operational Path A (recommended): Run SuperNode with `sn-manager`

`sn-manager` provides:

- stable install layout
- lifecycle control
- safe auto-updates (stable-only, same-major, and defers while gateway is busy)

### A1) Install `sn-manager` (SuperNode host)

#### Download and extract

```bash
curl -L https://github.com/LumeraProtocol/supernode/releases/latest/download/supernode-linux-amd64.tar.gz | tar -xz

```

#### Install to a user-writable location (enables self-update)

```bash
install -D -m 0755 sn-manager "$HOME/.sn-manager/bin/sn-manager"
"$HOME/.sn-manager/bin/sn-manager" version
```

#### Optional: add to PATH

```bash
echo 'export PATH="$HOME/.sn-manager/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc && hash -r
command -v -a sn-manager
readlink -f "$(command -v sn-manager)"
```

#### If you previously installed a global copy, remove it

```bash
sudo rm -f /usr/local/bin/sn-manager || true
hash -r
command -v -a sn-manager
readlink -f "$(command -v sn-manager)"

```

### A2) systemd service for `sn-manager` (SuperNode host)

Replace `<YOUR_USER>`:

```bash
sudo tee /etc/systemd/system/sn-manager.service >/dev/null <<EOF
[Unit]
Description=Lumera SuperNode Manager
After=network-online.target

[Service]
User=<YOUR_USER>
Environment=HOME=/home/<YOUR_USER>
WorkingDirectory=/home/<YOUR_USER>
ExecStart=/home/<YOUR_USER>/.sn-manager/bin/sn-manager start
Restart=on-failure
RestartSec=10
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now sn-manager
journalctl -u sn-manager -f

```

Note: systemd does not inherit your shell’s environment. If you initialized with `--keyring-passphrase-env SUPERNODE_PASSPHRASE`, set `SUPERNODE_PASSPHRASE` in the systemd unit via `Environment=` or `EnvironmentFile=`.

### A3) Initialize SuperNode via `sn-manager` (creates or imports your `SN_ACCOUNT` key)

> Note: Unrecognized flags to sn-manager init are passed through to supernode init.

#### Interactive mode

```bash
sn-manager init
```

#### Non-interactive mode (recommended pattern)

```bash
export SUPERNODE_PASSPHRASE="your-secure-passphrase"

sn-manager init -y \
  --auto-upgrade \
  --keyring-backend file \
  --keyring-passphrase-env SUPERNODE_PASSPHRASE \
  --key-name mySNKey \
  --supernode-addr 0.0.0.0 \
  --supernode-port 4444 \
  --lumera-grpc https://grpc.lumera.io:443 \
  --chain-id <CHAIN_ID>
```

#### If using Option 3 (recover an existing SN_ACCOUNT key)

If you use `-y` with `--recover`, you must also provide `--mnemonic` (or omit `-y` and follow the interactive prompts).

```bash
export SUPERNODE_PASSPHRASE="your-secure-passphrase"

sn-manager init -y \
  --auto-upgrade \
  --keyring-backend file \
  --keyring-passphrase-env SUPERNODE_PASSPHRASE \
  --key-name mySNWallet \
  --recover \
  --mnemonic "word1 word2 ... word24" \
  --supernode-addr 0.0.0.0 \
  --supernode-port 4444 \
  --lumera-grpc https://grpc.lumera.io:443 \
  --chain-id <CHAIN_ID>
```

### A4) Find your `SN_ACCOUNT` address

Use whichever key name you created/imported above:

```bash
lumerad keys show <sn_key_name> -a
```

Record it as:

- `SN_ACCOUNT=<lumera1...>`

### A5) Foundation-funded stake steps (Options 2 or 3)

If you are using foundation support:

1. Provide `SN_ACCOUNT` to the foundation (must be **fresh**)
2. Foundation sends funds (vesting: temporary or permanent lock)
3. **You delegate from SN_ACCOUNT to your validator**:

Run this on the machine that has the `SN_ACCOUNT` key (often the SuperNode host):

```bash
VALOPER="<lumeravaloper...>"
lumerad tx staking delegate "$VALOPER" <amount>ulume \
  --from <sn_key_name> \
  --chain-id <CHAIN_ID> --gas auto --gas-adjustment 1.3 --fees 7000ulume
```

**Also keep some validator self-delegation** (non-zero), typically from `<val_key>`:

```bash
VALOPER=$(lumerad keys show <val_key> --bech val -a)
lumerad tx staking delegate "$VALOPER" <small_amount>ulume \
  --from <val_key> \
  --chain-id <CHAIN_ID> --gas auto --gas-adjustment 1.3 --fees 7000ulume
```

### A6) Register the SuperNode (validator host)

Registration is signed by your **validator operator key** and must be run on the validator host.

```bash
VALOPER=$(lumerad keys show <val_key> --bech val -a)
SN_ENDPOINT="<SN_PUBLIC_IP>:4444"
SN_ACCOUNT="<lumera1...>"

lumerad tx supernode register-supernode \
  "$VALOPER" "$SN_ENDPOINT" "$SN_ACCOUNT" \
  --from <val_key> --chain-id <CHAIN_ID> \
  --gas auto --gas-adjustment 1.3 --fees 5000ulume
```

### A7) Common `sn-manager` operations

```bash
sn-manager status
sn-manager check
sn-manager ls
sn-manager ls-remote
sn-manager get <version>
sn-manager use <version>
sn-manager supernode status
sn-manager supernode start
sn-manager supernode stop
```

**Start/Stop behavior note:**
If systemd runs sn-manager and you call `sn-manager stop`, it exits cleanly (not a crash), so systemd may not restart it automatically. Use:

```bash
sudo systemctl start sn-manager

```

---

## Part B — Operational Path B (manual): Run SuperNode without `sn-manager`

Use this if you want to fully manage installation and upgrades yourself.

### B1) Install SuperNode binary (SuperNode host)

```bash
sudo curl -L -o /usr/local/bin/supernode \
  https://github.com/LumeraProtocol/supernode/releases/latest/download/supernode-linux-amd64
sudo chmod +x /usr/local/bin/supernode
supernode version
```

### B2) Keyring passphrase options (manual path)

If your keyring backend is `file` or `os`, you must provide a passphrase at init time.

Supported:

- `--keyring-passphrase`
- `--keyring-passphrase-env`
- `--keyring-passphrase-file`

Example:

```bash
export SUPERNODE_PASSPHRASE="your-secure-passphrase"
supernode init --key-name mySNKey --keyring-backend file --keyring-passphrase-env SUPERNODE_PASSPHRASE --chain-id <CHAIN_ID>
```

### B3) Initialize (create or recover the `SN_ACCOUNT` key)

#### Create new key (Options 1 or 2)

```bash
supernode init --key-name mySNKey --chain-id <CHAIN_ID>
```

#### Recover existing key (Option 3)

```bash
supernode init --key-name mySNWallet --recover --chain-id <CHAIN_ID>

```

### B4) Run SuperNode as a systemd service (manual)

Replace `<YOUR_USER>`:

```bash
sudo tee /etc/systemd/system/supernode.service >/dev/null <<EOF
[Unit]
Description=Lumera SuperNode
After=network-online.target

[Service]
User=<YOUR_USER>
ExecStart=/usr/local/bin/supernode start --basedir /home/<YOUR_USER>/.supernode
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now supernode
journalctl -u supernode -f

```

Note: systemd does not inherit your shell’s environment. If your keyring is configured with `--keyring-passphrase-env`, set that environment variable in the systemd unit via `Environment=` or `EnvironmentFile=`.

### B5) Find your `SN_ACCOUNT` address

```bash
lumerad keys show <sn_key_name> -a
```

### B6) Foundation-funded stake steps (Options 2 or 3)

Same as in Path A:

1. Provide `SN_ACCOUNT` to the foundation (fresh address)
2. Foundation sends vesting funds (temporary/permanent lock)
3. You delegate from `SN_ACCOUNT` to your validator:

```bash
VALOPER="<lumeravaloper...>"
lumerad tx staking delegate "$VALOPER" <amount>ulume \
  --from <sn_key_name> \
  --chain-id <CHAIN_ID> --gas auto --gas-adjustment 1.3 --fees 7000ulume
```

Keep some validator self-delegation (non-zero):

```bash
VALOPER=$(lumerad keys show <val_key> --bech val -a)
lumerad tx staking delegate "$VALOPER" <small_amount>ulume \
  --from <val_key> \
  --chain-id <CHAIN_ID> --gas auto --gas-adjustment 1.3 --fees 7000ulume
```

### B7) Register the SuperNode (validator host)

```bash
VALOPER=$(lumerad keys show <val_key> --bech val -a)
SN_ENDPOINT="<SN_PUBLIC_IP>:4444"
SN_ACCOUNT="<lumera1...>"

lumerad tx supernode register-supernode \
  "$VALOPER" "$SN_ENDPOINT" "$SN_ACCOUNT" \
  --from <val_key> --chain-id <CHAIN_ID> \
  --gas auto --gas-adjustment 1.3 --fees 5000ulume
```

---

### 5) Verify registration

#### On-chain SuperNode status (validator host)

```bash
VALOPER=$(lumerad keys show <val_key> --bech val -a)
lumerad q supernode get-supernode "$VALOPER"
```

Expected state: `SUPERNODE_STATE_ACTIVE`

If you see stake/eligibility failures:

- confirm validator has **non-zero** self-delegation
- confirm `SN_ACCOUNT` you registered is the same account that delegated to your validator
- confirm the delegation of at least 25K (on **mainnet**) from `SN_ACCOUNT` to your validator exists

---

### 6) Security and operational best practices

- Separate hosts: validator ≠ SuperNode
- Back up mnemonics:
  - validator operator key mnemonic
  - `SN_ACCOUNT` mnemonic
- Prefer `keyring-backend os` on production servers when available and operationally supported
- Minimize exposed ports to only what’s required (4444/8002/4445)
- Treat `SN_ACCOUNT` as operational-critical: if you lose the key, you may lose the ability to manage delegation flow (even if funds are vesting-locked)

---

### 7) Troubleshooting (common)

#### “Foundation funded my SN_ACCOUNT but eligibility still fails”

Most common causes:

- validator has **zero** self-delegation
- `SN_ACCOUNT` did not delegate to your validator (funds sitting idle)
- you registered with a different `SN_ACCOUNT` than the one that delegated

#### “sn-manager auto-update fails / install not writable”

`sn-manager` must be installed under a user-writable path (recommended: `~/.sn-manager/bin/sn-manager`).
Remove any `/usr/local/bin/sn-manager` copy and ensure `command -v sn-manager` resolves to your home install.

#### “SuperNode running but endpoint not reachable”

- verify firewall rules on `4444/tcp`, `8002/tcp`, `4445/tcp`
- confirm your `SN_ENDPOINT` matches your public IP/DNS and port `4444`
- check logs:
  - `journalctl -u sn-manager -f`
  - or `journalctl -u supernode -f`

---

### 8) Checklist summary

**Before registration**

- [ ]  SuperNode host is up and ports are open (4444/8002/4445)
- [ ]  `SN_ACCOUNT` key exists and you can sign transactions with it
- [ ]  validator has non-zero self-delegation
- [ ]  if foundation-funded: funds arrived to SN_ACCOUNT and you delegated SN_ACCOUNT → validator

**Registration**

- [ ]  run `register-supernode` on validator host signed by `<val_key>`
- [ ]  pass correct `SN_ENDPOINT` and correct `SN_ACCOUNT`

**After**

- [ ]  query `get-supernode` and confirm `ACTIVE`
- [ ]  monitor service logs and system health

---

© Lumera Protocol — SuperNode Guide (sn-manager + LEP-3 Dual-Source Stake)
