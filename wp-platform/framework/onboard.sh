#!/bin/bash
set -e

# -------------------------------
# FLAGS
# -------------------------------
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

echo "🚀 WordPress Client Onboarding"
[[ "$DRY_RUN" == "true" ]] && echo "⚠️  DRY-RUN MODE ENABLED"
[[ "$AUTO_DEPLOY" == "true" ]] && echo "⚡ AUTO-DEPLOY ENABLED"

# -------------------------------
# INPUT
# -------------------------------
read -p "Client ID (short, unique): " CLIENT
read -p "Client Domain (example.client.com): " DOMAIN
read -p "Plan (starter | pro | enterprise): " PLAN
read -s -p "DB password: " DB_PASS; echo
read -s -p "DB root password: " DB_ROOT; echo

# -------------------------------
# PLAN → RESOURCE MAPPING
# -------------------------------
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

# -------------------------------
# DIRECTORY SETUP
# -------------------------------
run "mkdir -p \
  '$BASE/data/wp' \
  '$BASE/data/mysql' \
  '$BASE/data/redis'"

# -------------------------------
# COPY TEMPLATES
# -------------------------------
run "cp framework/template/docker-compose.yml.tpl '$BASE/docker-compose.yml'"
run "cp framework/template/wp-config-extra.php.tpl '$BASE/wp-config-extra.php'"

# -------------------------------
# TEMPLATE SUBSTITUTION
# -------------------------------
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

# -------------------------------
# DEPLOY LOGIC
# -------------------------------
if [[ "$AUTO_DEPLOY" == "true" ]]; then
  run "docker compose -f '$BASE/docker-compose.yml' up -d"
else
  echo ""
  read -p "🚀 Deploy client stack now? (y/N): " DEPLOY
  if [[ "$DEPLOY" == "y" || "$DEPLOY" == "Y" ]]; then
    run "docker compose -f '$BASE/docker-compose.yml' up -d"
  else
    echo "ℹ️ Deployment skipped"
  fi
fi

# -------------------------------
# SUMMARY
# -------------------------------
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
echo "$DOMAIN  →  platform.justbots.tech"
echo "Proxy: DNS-only"
echo ""

[[ "$DRY_RUN" == "true" ]] && echo "⚠️  No changes were applied (dry-run)"