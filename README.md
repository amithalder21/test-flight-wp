---

# 🚀 WordPress Multi-Client Platform (Docker + Traefik)

A **production-grade, multi-tenant WordPress platform** built with **Docker**, **Traefik**, and **Redis**, designed for **SaaS-style onboarding** where **each client is fully isolated**, fast, and scalable.

---

## ✨ Key Features

* ✅ **Isolated WordPress per client**

  * Separate containers
  * Separate MySQL
  * Separate Redis
* ⚡ **High performance**

  * Redis object cache
  * Disabled WP cron (external-ready)
  * Reduced DB overhead
* 🔐 **Secure by default**

  * Reverse-proxy aware (Traefik / Cloudflare)
  * No shared cookies
  * No cross-client leakage
* 🌍 **Ingress via Traefik**

  * Host-based routing
  * Automatic SSL (ACME / Cloudflare Origin)
* 🧩 **Plan-based resource control**

  * CPU & memory limits per client
* 🛠 **Automated onboarding**

  * Single script creates & deploys a client
  * Dry-run supported
* 📦 **Future-ready**

  * Horizontal scaling possible
  * Session support (optional)
  * APM / monitoring friendly

---

## 🏗 Architecture (High Level)

```
Browser
  ↓
Traefik (Ingress + SSL)
  ↓
Client WordPress (Apache/PHP)
  ↓
MySQL + Redis (isolated per client)
```

Each client runs in **its own Docker network** and **cannot see other clients**.

---

## 📁 Project Structure

```
.
├── ingress/
│   ├── docker-compose.yml        # Traefik ingress
│   ├── letsencrypt/              # ACME storage
│   └── certs/                    # (optional) Origin certs
│
├── framework/
│   └── template/
│       ├── docker-compose.yml.tpl
│       └── wp-config-extra.php.tpl
│
├── onboard.sh                    # Client onboarding script
│
├── clients/
│   └── <client-id>/
│       ├── docker-compose.yml
│       ├── wp-config-extra.php
│       └── data/
│           ├── wp/
│           ├── mysql/
│           └── redis/
└── README.md
```

---

## 🚦 Prerequisites

* Docker 24+
* Docker Compose v2
* Linux host (recommended)
* Public IP (for SSL)
* DNS access (Cloudflare / Route53 / etc.)

---

## 🔐 SSL Strategy

You can use **either**:

### Option A (Recommended for SaaS)

**Cloudflare Origin SSL**

* Works with CNAME
* No Let’s Encrypt rate limits
* Best for multi-tenant platforms

### Option B

**Traefik ACME (Let’s Encrypt)**

* Requires:

  * A-record to server
  * Port 80 open
  * Proxy OFF (DNS-only)
* Use **staging** for testing

---

## 🚀 Getting Started

### 1️⃣ Create Traefik network (once)

```bash
docker network create proxy
```

---

### 2️⃣ Start Traefik ingress

```bash
cd ingress
docker compose up -d
```

---

### 3️⃣ Onboard a new client

```bash
./onboard.sh
```

Supports:

* Plan selection (`starter`, `pro`, `enterprise`)
* Dry run:

```bash
./onboard.sh --dry-run
```

---

### 4️⃣ DNS for client

```text
client.example.com → platform.example.com
```

(Proxy mode depends on SSL strategy.)

---

## 📦 Plans & Resources (Example)

| Plan       | CPU | Memory | Redis |
| ---------- | --- | ------ | ----- |
| Starter    | 0.5 | 512MB  | 128MB |
| Pro        | 1.5 | 1.5GB  | 256MB |
| Enterprise | 4.0 | 4GB    | 1GB   |

---

## 🧠 WordPress Optimizations Included

* Redis object cache
* Cache key isolation per client
* Disabled autosave spam
* Limited post revisions
* Reverse proxy HTTPS awareness
* Safe defaults for SaaS

Optional (commented by default):

* Redis-backed PHP sessions (WooCommerce, LMS)

---

## ⚠️ Important Notes

* Plugin/theme installs require **single replica**
* Do not enable horizontal scaling while file installs are enabled
* Sessions should only be enabled when required
* `COOKIE_DOMAIN` must **not** be manually set (handled by WP)

---

## 🧪 Development & Testing

* Use **Let’s Encrypt staging** for testing
* Clear cookies after config changes
* Preserve `acme.json` to avoid rate limits

---

## 🛣 Roadmap Ideas

* Client upgrade / downgrade script
* Horizontal scaling with shared storage
* Plugin marketplace
* Per-client metrics & APM
* Backup automation
* Admin UI for onboarding

---

## 🤝 Contributing

PRs welcome.
This project values:

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
If you treat WordPress as **infrastructure**, this platform does it right.

---
