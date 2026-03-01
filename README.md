---

# 🚀 WordPress Multi-Client SaaS Platform

**Docker + Traefik + Redis + Komodo**

A **production-grade, multi-tenant WordPress SaaS platform** built with Docker, Traefik, Redis, and a centralized control plane (Komodo).
Designed for **real SaaS onboarding**, where **each client is fully isolated, secure, fast, and scalable**.

---

## ✨ Key Features

### ✅ True Client Isolation

* Separate containers per client
* Separate **MySQL** per client
* Separate **Redis** per client
* Separate Docker networks
* No shared cookies or data leakage

### ⚡ High Performance by Default

* Redis Object Cache enabled
* WP-Cron disabled (external / platform-ready)
* Reduced database overhead
* Optimized WordPress runtime config

### 🔐 Secure by Design

* Reverse-proxy aware (Traefik / Cloudflare)
* HTTPS enforced at ingress
* No cross-client filesystem access
* Safe defaults for multi-tenant SaaS

### 🌍 Ingress via Traefik

* Host-based routing
* Automatic SSL (Let’s Encrypt ACME)
* Cloudflare Origin SSL supported
* Centralized ingress for all clients

### 🧩 Plan-Based Resource Control

* CPU & memory limits per client
* Predictable performance tiers
* Vertical scaling first (safe)

### 🛠 Automated Onboarding

* Single script to create & deploy clients
* Preflight checks included
* Dry-run supported
* Optional auto-deploy

### 📦 Future-Ready

* Horizontal scaling possible
* Redis-backed PHP sessions (optional)
* Monitoring & APM friendly
* Control-plane ready (Komodo)

---

## 🏗 High-Level Architecture

```
Browser
  ↓
Traefik (Ingress + SSL)
  ↓
Client WordPress (Apache / PHP)
  ↓
MySQL + Redis (isolated per client)
```

Each client runs in its **own Docker network** and **cannot see any other client**.

---

## 📁 Repository Structure

```
.
├── README.md
│
├── control-plane/
│   ├── docker-compose.yml        # Komodo + MongoDB
│   └── data/                     # Komodo state (bind mount)
│
├── wp-platform/
│   ├── ingress/
│   │   ├── docker-compose.yml    # Traefik ingress
│   │   └── letsencrypt/          # ACME storage (acme.json)
│   │
│   ├── framework/
│   │   └── template/
│   │       ├── docker-compose.yml.tpl
│   │       └── wp-config-extra.php.tpl
│   │
│   ├── clients/
│   │   └── <client-id>/
│   │       ├── docker-compose.yml
│   │       ├── wp-config-extra.php
│   │       └── data/
│   │           ├── wp/
│   │           ├── uploads/
│   │           ├── mysql/
│   │           └── redis/
│   │
│   └── letsencrypt/
│
└── onboard.sh                    # Client onboarding script
```

---

## 🚦 Prerequisites

* Docker **24+**
* Docker Compose v2
* Linux host (recommended)
* Public IP (for SSL)
* DNS access (Cloudflare / Route53 / etc.)

---

## 🔐 SSL Strategy

### Option A — **Recommended for SaaS**

**Cloudflare Origin SSL**

* Works with CNAME
* No Let’s Encrypt rate limits
* Ideal for multi-tenant platforms

### Option B — Traefik ACME (Let’s Encrypt)

Requirements:

* A record → server IP
* Port 80 open
* Cloudflare proxy **OFF** (DNS-only)
* Use **staging** during testing

---

## 🚀 Getting Started

### 1️⃣ Create Traefik network (once)

```bash
docker network create proxy
```

### 2️⃣ Start Traefik ingress

```bash
cd wp-platform/ingress
docker compose up -d
```

### 3️⃣ Onboard a new client

```bash
./onboard.sh
```

Supports:

* Plan selection (`starter | pro | enterprise`)
* Dry-run mode:

```bash
./onboard.sh --dry-run
```

### 4️⃣ DNS for client

```
client.example.com  →  platform.example.com
```

(Proxy mode depends on SSL strategy.)

---

## 📦 Plans & Resource Allocation (Example)

| Plan       | WP CPU | WP RAM | MySQL CPU | MySQL RAM | InnoDB Pool | Max Conn | Redis RAM |
| ---------- | ------ | ------ | --------- | --------- | ----------- | -------- | --------- |
| Starter    | 0.5    | 512M   | 0.5       | 768M      | 256M        | 80       | 64MB      |
| Pro        | 1.5    | 1.5G   | 1.0       | 1.5G      | 512M        | 150      | 128MB     |
| Enterprise | 4.0    | 4G     | 2.0       | 3G        | 1G          | 300      | 256MB     |

---

## 🧠 WordPress Optimizations Included

* Redis Object Cache
* Cache key isolation per client
* Disabled autosave spam
* Limited post revisions
* Reverse-proxy HTTPS awareness
* SaaS-safe defaults

**Optional (commented by default):**

* Redis-backed PHP sessions (WooCommerce, LMS)

---

## ⚠️ Important Notes

* Plugin/theme installs require **single replica**
* Do **not** enable horizontal scaling while file installs are enabled
* Sessions should only be enabled when required
* `COOKIE_DOMAIN` must **not** be manually set (handled by WordPress)

---

## 🧪 Development & Testing

* Use Let’s Encrypt **staging** for testing
* Clear cookies after config changes
* Preserve `acme.json` to avoid rate limits

---

## 🧠 Control Plane (Komodo)

The platform includes **Komodo** for centralized visibility:

* Docker workload insight
* Server health
* Resource usage
* Automation & orchestration

> Komodo **does not replace Docker Compose**
> It **observes and controls** the platform safely

---

## 🛣 Roadmap Ideas

* Client upgrade / downgrade automation
* Horizontal scaling with shared storage
* Plugin marketplace
* Per-client metrics & APM
* Backup automation
* Admin UI for onboarding

---

## 🤝 Contributing

PRs welcome. This project values:

* Simplicity
* Isolation
* Predictable behavior
* Production safety

---

## 📜 License

MIT (or your choice)

---

## 🏁 Final Note

This project is designed for **real SaaS use**, not demos.
If you treat **WordPress as infrastructure**, this platform does it right.

---
