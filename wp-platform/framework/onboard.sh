#!/bin/bash
set -e

# =========================================================
# FLAGS
# =========================================================
DRY_RUN=false
AUTO_DEPLOY=false

for arg in "$@"; do
  case $arg in
    --dry-run|-n)
      DRY_RUN=true
      ;;
    --deploy|-d)
      AUTO_DEPLOY=true
      ;;
  esac
done

run() {
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "[DRY-RUN] $*"
  else
    eval "$@"
  fi
}

is_container_running() {
  docker inspect -f '{{.State.Running}}' "$1" 2>/dev/null || echo "false"
}

echo "🚀 WordPress Client Onboarding"
[[ "$DRY_RUN" == "true" ]] && echo "⚠️  DRY-RUN MODE ENABLED"
[[ "$AUTO_DEPLOY" == "true" ]] && echo "⚡ AUTO-DEPLOY ENABLED"

# =========================================================
# PREFLIGHT CHECKS
# =========================================================
echo ""
echo "🔍 Preflight checks..."

# -------------------------------
# Docker availability
# -------------------------------
if ! command -v docker >/dev/null 2>&1; then
  echo "❌ Docker is not installed or not in PATH"
  exit 1
fi

# -------------------------------
# ACME STORAGE SAFETY CHECK
# -------------------------------
echo "🔐 Checking ACME storage (Let's Encrypt)..."

if [[ ! -d "letsencrypt" ]]; then
  run "mkdir -p letsencrypt"
fi

if [[ ! -f "letsencrypt/acme.json" ]]; then
  run "touch letsencrypt/acme.json"
fi

CURRENT_PERMS=$(stat -c "%a" letsencrypt/acme.json 2>/dev/null || echo "000")
if [[ "$CURRENT_PERMS" != "600" ]]; then
  run "chmod 600 letsencrypt/acme.json"
fi

echo "✅ ACME storage ready"

# -------------------------------
# Proxy network check
# -------------------------------
if ! docker network inspect proxy >/dev/null 2>&1; then
  echo "⚠️  Docker network 'proxy' not found"
  if [[ "$AUTO_DEPLOY" == "true" ]]; then
    run "docker network create proxy"
  else
    read -p "Create Docker network 'proxy'? (y/N): " CREATE_NET
    [[ "$CREATE_NET" =~ ^[Yy]$ ]] || exit 1
    run "docker network create proxy"
  fi
fi

# -------------------------------
# Traefik check
# -------------------------------
TRAEFIK_RUNNING=$(is_container_running traefik)

if [[ "$TRAEFIK_RUNNING" != "true" ]]; then
  echo "⚠️  Traefik is not running"
  if [[ "$AUTO_DEPLOY" == "true" ]]; then
    run "docker compose -f ingress/docker-compose.yml up -d"
  else
    read -p "🚦 Deploy Traefik now? (y/N): " DEPLOY_TRAEFIK
    [[ "$DEPLOY_TRAEFIK" =~ ^[Yy]$ ]] || exit 1
    run "docker compose -f ingress/docker-compose.yml up -d"
  fi
else
  echo "✅ Traefik is running"
fi

# =========================================================
# INPUT
# =========================================================
echo ""
read -p "Client ID (short, unique): " CLIENT
read -p "Client Domain (example.client.com): " DOMAIN
read -p "Plan (starter | pro | enterprise): " PLAN
read -s -p "DB password: " DB_PASS; echo
read -s -p "DB root password: " DB_ROOT; echo

# =========================================================
# PLAN → RESOURCE MAPPING
# =========================================================
case "$PLAN" in
  starter)
    WP_CPUS="0.50"
    WP_MEMORY="512M"
    REDIS_MEMORY="128mb"
    ;;
  pro)
    WP_CPUS="1.50"
    WP_MEMORY="1536M"
    REDIS_MEMORY="256mb"
    ;;
  enterprise)
    WP_CPUS="4.00"
    WP_MEMORY="4096M"
    REDIS_MEMORY="1024mb"
    ;;
  *)
    echo "❌ Invalid plan: $PLAN"
    exit 1
    ;;
esac

BASE="clients/$CLIENT"

# =========================================================
# DIRECTORY SETUP
# =========================================================
run "mkdir -p \
  '$BASE/data/wp' \
  '$BASE/data/mysql' \
  '$BASE/data/redis'"

# =========================================================
# COPY TEMPLATES
# =========================================================
run "cp framework/template/docker-compose.yml.tpl '$BASE/docker-compose.yml'"
run "cp framework/template/wp-config-extra.php.tpl '$BASE/wp-config-extra.php'"

# =========================================================
# TEMPLATE SUBSTITUTION
# =========================================================
run "sed -i \
  -e 's/__CLIENT__/$CLIENT/g' \
  -e 's/__DOMAIN__/$DOMAIN/g' \
  -e 's/__DB_PASS__/$DB_PASS/g' \
  -e 's/__DB_ROOT__/$DB_ROOT/g' \
  -e 's/__WP_CPUS__/$WP_CPUS/g' \
  -e 's/__WP_MEMORY__/$WP_MEMORY/g' \
  -e 's/__REDIS_MEMORY__/$REDIS_MEMORY/g' \
  '$BASE/docker-compose.yml'"

run "sed -i \
  -e 's/__CLIENT__/$CLIENT/g' \
  '$BASE/wp-config-extra.php'"

# =========================================================
# DEPLOY CLIENT STACK
# =========================================================
if [[ "$AUTO_DEPLOY" == "true" ]]; then
  run "docker compose -f '$BASE/docker-compose.yml' up -d"
else
  echo ""
  read -p "🚀 Deploy client stack now? (y/N): " DEPLOY
  if [[ "$DEPLOY" =~ ^[Yy]$ ]]; then
    run "docker compose -f '$BASE/docker-compose.yml' up -d"
  else
    echo "ℹ️ Deployment skipped"
  fi
fi

# =========================================================
# SUMMARY
# =========================================================
echo ""
echo "✅ Onboarding completed"
echo "--------------------------------"
echo "Client ID : $CLIENT"
echo "Domain    : $DOMAIN"
echo "Plan      : $PLAN"
echo "CPU       : $WP_CPUS"
echo "Memory    : $WP_MEMORY"
echo "Redis Mem : $REDIS_MEMORY"
echo ""
echo "DNS:"
echo "CNAME  $DOMAIN  →  platform.justbots.tech"
echo "Proxy : DNS-only"
echo ""
echo "SSL:"
echo "Issued automatically by Traefik (Let's Encrypt)"
echo ""

[[ "$DRY_RUN" == "true" ]] && echo "⚠️  DRY-RUN COMPLETE — no changes applied"