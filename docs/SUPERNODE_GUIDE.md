# Lumera SuperNode ― **Operator Runbook (v1.1)**

> **Scope** – end-to-end steps for a validator operator to
>
> 1. provision hardware,
> 2. install and configure the SuperNode binary,
> 3. satisfy the **≥ 25 000 LUME** self-bond rule, and
> 4. register the SuperNode on-chain – even when the validator lives on a separate, hardened box.

---

## 1  Why run a SuperNode?

SuperNodes add extra services (such as storage (“Cascade”), AI and others) on top of standard block validation and earn **Proof-of-Service (PoSe)** rewards in parallel with PoS staking rewards. Each validator may attach **one** SuperNode .

---

## 2  Prerequisites

| Item                   | Minimum                                           | Recommended                   | Notes                                              |
| ---------------------- | ------------------------------------------------- | ----------------------------- | -------------------------------------------------- |
| CPU / RAM / Disk       | 8 × vCPU · 16 GB · 1 TB NVMe                      | 16 × vCPU · 64 GB · 4 TB NVMe |                                                    |
| Network                | 1 Gbps                                            | 5 Gbps                        |                                                    |
| OS                     | Ubuntu 22.04 LTS (or newer)                       | –                             | Install `build-essential`                          |
| Ports (SuperNode host) | **4444** (gRPC/API) & **4445** (P2P) open inbound | –                             | Do **not** change 4445                             |
| Validator              | Running `lumerad`, **self-bond ≥ 25 000 LUME**¹   | –                             | Self-bond may sit on a separate signer/Horcrux box |

¹ Required only if the validator is **not** already in the active set .

---

## 3  Install the SuperNode binary

```bash
# Download single, statically linked binary
sudo curl -L \
  -o /usr/local/bin/supernode \
  https://github.com/lumera-network/supernode/releases/latest/download/supernode-linux-amd64

sudo chmod +x /usr/local/bin/supernode
supernode version
```

---

## 4  Create base directory & configuration

```bash
sudo mkdir -p /var/lib/supernode/{data/p2p,keys,raptorq_files}
sudo chown $USER /var/lib/supernode -R
cd /var/lib/supernode
```

### `config.yml` template

```yaml
supernode:
  key_name:  mykey
  identity:  ""              # Paste the Bech32 address after key creation
  ip_address: 0.0.0.0        # or public DNS/IP
  port: 4444                 # gRPC/API port

keyring:
  backend: file              # file|os|test
  dir: keys

p2p:
  listen_address: 0.0.0.0
  port: 4445                 # do NOT change
  data_dir: data/p2p
  bootstrap_nodes: ""
  external_ip: ""            # leave blank for auto-detect

lumera:
  # Option A – local full node / sentry
  #grpc_addr: "localhost:9090"
  # Option B – public endpoint (no local lumerad needed)
  grpc_addr: "grpc.lumera.io:443"
  chain_id: "lumera-mainnet-1"

raptorq:
  files_dir: raptorq_files
```

> **Only gRPC access is required.** Point `lumera.grpc_addr` either at a local read-only full node (sentry) or at the public endpoint **grpc.lumera.io:443**.

---

## 5  Key management

```bash
# Generate a key
supernode keys add mykey -c /var/lib/supernode/config.yml

# ...or recover from mnemonic
supernode keys recover mykey "<24-word mnemonic>" -c /var/lib/supernode/config.yml
```

Copy the printed address (`lumera1…`) into `supernode.identity` in `config.yml`.

---

## 6  Meet the 25 000 LUME self-bond (if needed)

On your **validator** host / Horcrux signer:

```bash
# Check current self-bond
VALOPER=$(lumerad keys show <val> --bech val -a)
lumerad q staking validator $VALOPER --output json | jq .selfBond

# Top-up if below 25 000 LUME
lumerad tx staking delegate $VALOPER 25000000000ulume \
  --from <wallet> --chain-id lumera-mainnet-1 --gas auto --fees 5000ulume
```

---

## 7  Register the SuperNode

Run this **on the validator signer box** (where the operator key lives):

```bash
SN_HOST="sn1.example.com"       # public DNS / IP of SuperNode host
VALOPER=$(lumerad keys show <val> --bech val -a)
SN_ACCOUNT=<supernode-account> # `lumera1…` created int the step 5

lumerad tx supernode register \
  $VALOPER $SN_HOST \
  --from <val> \x
  --gas auto --fees 5000ulume --chain-id lumera-mainnet-1
```

The module verifies (a) signature by the validator operator and (b) self-bond ≥ 25 k when the validator is outside the active set .

---

## 8  Systemd service (SuperNode host)

```bash
sudo tee /etc/systemd/system/supernode.service <<'EOF'
[Unit]
Description=Lumera SuperNode
After=network-online.target

[Service]
User=supernode
ExecStart=/usr/local/bin/supernode start -c /var/lib/supernode/config.yml
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now supernode
journalctl -u supernode -f
```

You should see `state=ACTIVE` logs soon after the registration tx is final.

---

## 9  Verify

```bash
# From anywhere:
lumerad q supernode get $VALOPER \
  --node https://rpc.lumera.io:443

# Expected JSON fields
#  "state": "ACTIVE",
#  "ip_address": "sn1.example.com:4444",
#  "version": "<current version>"
```

---

## 10  Every-day commands

| Purpose             | Example                                                                  |
| ------------------- | ------------------------------------------------------------------------ |
| Stop SN voluntarily | `lumerad tx supernode stop $VALOPER --from <val> ...`                    |
| Restart / change IP | `lumerad tx supernode start $VALOPER new.ip:4444 --from <val>`           |
| Upgrade software    | `lumerad tx supernode update $VALOPER $SN_HOST:4444 v1.2.0 --from <val>` |
| Deregister forever  | `lumerad tx supernode deregister $VALOPER --from <val>`                  |

---

## 11  Security checklist

* **Separate hosts** – keep SuperNode away from the validator signing key .
* Use `keyring.backend = os` (or HSM) for production.
* Restrict inbound to 4444/4445 only; use WireGuard/Nebula for private gRPC if needed.
* Monitor `journalctl`, Prometheus, or a log shipper for crashes and state changes.
* Patch promptly – the SuperNode binary is statically built; replace the file and `update` on-chain.

---

## 12  Quick-start crib sheet (TL;DR)

1. `curl …/supernode-linux-amd64 | sudo tee /usr/local/bin/supernode && chmod +x`
2. Write `config.yml`, point `grpc_addr` to **grpc.lumera.io:443**.
3. `supernode keys add mykey -c …`, paste address into `identity`.
4. Ensure validator self-bond ≥ 25 000 LUME.
5. On validator signer: `tx supernode register <valoper> <SN_IP> <supernode-account>`.
6. `systemctl enable --now supernode`.
7. `q supernode get <valoper>` shows `ACTIVE` – you’re earning PoSe rewards!

---

### References

SuperNode design (stake rules, separate hosting) .
Lumera architecture & dual PoS/PoSe incentives .
