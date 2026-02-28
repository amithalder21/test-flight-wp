#!/bin/bash
set -e

echo "🚀 WordPress Client Onboarding (Proxy-Ready)"

read -p "Client ID (short, unique): " CLIENT
read -p "Domain (example.com): " DOMAIN
read -s -p "DB password: " DB_PASS; echo
read -s -p "DB root password: " DB_ROOT; echo

BASE="clients/$CLIENT"

mkdir -p \
  "$BASE/data/wp" \
  "$BASE/data/mysql" \
  "$BASE/data/redis"

cp framework/template/docker-compose.yml.tpl \
   "$BASE/docker-compose.yml"

cp framework/template/wp-config-extra.php.tpl \
   "$BASE/wp-config-extra.php"

sed -i "s/__CLIENT__/$CLIENT/g" \
  "$BASE/docker-compose.yml" \
  "$BASE/wp-config-extra.php"

sed -i "s/__DOMAIN__/$DOMAIN/g" \
  "$BASE/docker-compose.yml"

sed -i "s/__DB_PASS__/$DB_PASS/g" \
  "$BASE/docker-compose.yml"

sed -i "s/__DB_ROOT__/$DB_ROOT/g" \
  "$BASE/docker-compose.yml"

echo "✅ Client created: $CLIENT"
echo "➡ Start:"
echo "docker compose -f $BASE/docker-compose.yml up -d"