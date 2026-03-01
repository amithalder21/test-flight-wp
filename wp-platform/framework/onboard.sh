#!/bin/bash
set -e

# =========================================================
# FLAGS
# =========================================================
DRY_RUN=false
AUTO_DEPLOY=false

for arg in "$@"; do
  case $arg in
    --dry-run|-n) DRY_RUN=true ;;
    --deploy|-d)  AUTO_DEPLOY=true ;;
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

# Docker check
command -v docker >/dev/null 2>&1 || { echo "❌ Docker not installed"; exit 1; }

# ACME storage (root)
run "mkdir -p letsencrypt"
run "touch letsencrypt/acme.json"
run "chmod 600 letsencrypt/acme.json"

# Proxy network
if ! docker network inspect proxy >/dev/null 2>&1; then
  echo "⚠️  Docker network 'proxy' not found"
  [[ "$AUTO_DEPLOY" == "true" ]] || read -p "Create Docker network 'proxy'? (y/N): " CONFIRM
  [[ "$AUTO_DEPLOY" == "true" || "$CONFIRM" =~ ^[Yy]$ ]] || exit 1
  run "docker network create proxy"
fi

# Traefik ACME storage
run "mkdir -p ingress/letsencrypt"
run "touch ingress/letsencrypt/acme.json"
run "chmod 600 ingress/letsencrypt/acme.json"

# Traefik check
if [[ "$(is_container_running traefik)" != "true" ]]; then
  echo "⚠️  Traefik is not running"
  [[ "$AUTO_DEPLOY" == "true" ]] || read -p "🚦 Deploy Traefik now? (y/N): " DEPLOY_TRAEFIK
  [[ "$AUTO_DEPLOY" == "true" || "$DEPLOY_TRAEFIK" =~ ^[Yy]$ ]] || exit 1
  run "docker compose -f ingress/docker-compose.yml up -d"
else
  echo "✅ Traefik is running"
fi

# =========================================================
# INPUT
# =========================================================
echo ""
read -p "Client ID (short, unique): " CLIENT
read -p "Client Domain (example.com): " DOMAIN
read -p "Plan (starter | pro | enterprise): " PLAN

read -p "WordPress replicas (default 1): " WP_SCALE
WP_SCALE=${WP_SCALE:-1}

if ! [[ "$WP_SCALE" =~ ^[0-9]+$ ]] || [[ "$WP_SCALE" -lt 1 ]]; then
  echo "❌ Invalid replica count"
  exit 1
fi

if [[ "$WP_SCALE" -gt 1 ]]; then
  echo "⚠️  Multiple replicas enabled — ensure immutable filesystem"
fi

read -s -p "DB password: " DB_PASS; echo
read -s -p "DB root password: " DB_ROOT; echo

# =========================================================
# PLAN → RESOURCE MAPPING (REDUCED & REALISTIC)
# =========================================================
case "$PLAN" in
  starter)
    WP_CPUS="0.50"
    WP_MEMORY="512M"

    MYSQL_CPUS="0.50"
    MYSQL_MEMORY="768M"
    MYSQL_BUFFER_POOL="256M"
    MYSQL_MAX_CONN="80"

    REDIS_MEMORY="64mb"
    ;;
  pro)
    WP_CPUS="1.50"
    WP_MEMORY="1536M"

    MYSQL_CPUS="1.00"
    MYSQL_MEMORY="1536M"
    MYSQL_BUFFER_POOL="512M"
    MYSQL_MAX_CONN="150"

    REDIS_MEMORY="128mb"
    ;;
  enterprise)
    WP_CPUS="4.00"
    WP_MEMORY="4096M"

    MYSQL_CPUS="2.00"
    MYSQL_MEMORY="3072M"
    MYSQL_BUFFER_POOL="1024M"
    MYSQL_MAX_CONN="300"

    REDIS_MEMORY="256mb"
    ;;
  *)
    echo "❌ Invalid plan"
    exit 1
    ;;
esac

BASE="clients/$CLIENT"

# =========================================================
# DIRECTORY SETUP
# =========================================================
run "mkdir -p \
  '$BASE/data/wp' \
  '$BASE/data/uploads' \
  '$BASE/data/mysql'"

# Uploads permission fix
run "chown -R 33:33 '$BASE/data/uploads'"
run "chmod 755 '$BASE/data/uploads'"

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
  -e 's/__MYSQL_CPUS__/$MYSQL_CPUS/g' \
  -e 's/__MYSQL_MEMORY__/$MYSQL_MEMORY/g' \
  -e 's/__MYSQL_BUFFER_POOL__/$MYSQL_BUFFER_POOL/g' \
  -e 's/__MYSQL_MAX_CONN__/$MYSQL_MAX_CONN/g' \
  -e 's/__REDIS_MEMORY__/$REDIS_MEMORY/g' \
  '$BASE/docker-compose.yml'"

run "sed -i 's/__CLIENT__/$CLIENT/g' '$BASE/wp-config-extra.php'"

# =========================================================
# DEPLOY CLIENT STACK
# =========================================================
if [[ "$AUTO_DEPLOY" == "true" ]]; then
  run "docker compose -f '$BASE/docker-compose.yml' up -d --scale wordpress=$WP_SCALE"
else
  read -p "🚀 Deploy client stack now? (y/N): " DEPLOY
  [[ "$DEPLOY" =~ ^[Yy]$ ]] && run "docker compose -f '$BASE/docker-compose.yml' up -d --scale wordpress=$WP_SCALE"
fi

# =========================================================
# SUMMARY
# =========================================================
echo ""
echo "✅ Onboarding completed"
echo "--------------------------------"
echo "Client    : $CLIENT"
echo "Domain    : $DOMAIN"
echo "Plan      : $PLAN"
echo "Replicas  : $WP_SCALE"
echo "WP CPU    : $WP_CPUS"
echo "WP RAM    : $WP_MEMORY"
echo "MySQL RAM : $MYSQL_MEMORY"
echo "Redis RAM : $REDIS_MEMORY"
echo ""
echo "DNS  : CNAME $DOMAIN → platform.justbots.tech"
echo "SSL  : Issued automatically by Traefik"
echo ""

[[ "$DRY_RUN" == "true" ]] && echo "⚠️  DRY-RUN COMPLETE — no changes applied"
