#!/bin/bash
set -e

echo "🚀 Fully Isolated WordPress Onboarding (Traefik)"

read -p "Client ID (short, no spaces): " CLIENT
read -p "Domain (e.g. site.client.com): " DOMAIN

while true; do
  read -s -p "DB password (required): " DB_PASS
  echo ""
  [ -n "$DB_PASS" ] && break
  echo "❌ DB password cannot be empty"
done

while true; do
  read -s -p "DB root password (required): " DB_ROOT
  echo ""
  [ -n "$DB_ROOT" ] && break
  echo "❌ DB root password cannot be empty"
done

BASE="clients/$CLIENT"
mkdir -p "$BASE/data/wp" "$BASE/data/mysql" "$BASE/data/redis"

cp template/docker-compose.yml.tpl "$BASE/docker-compose.yml"
cp template/nginx.conf.tpl "$BASE/nginx.conf"

sed -i "s|__CLIENT__|$CLIENT|g" "$BASE/docker-compose.yml" "$BASE/nginx.conf"
sed -i "s|__DOMAIN__|$DOMAIN|g" "$BASE/docker-compose.yml" "$BASE/nginx.conf"
sed -i "s|__DB_PASS__|$DB_PASS|g" "$BASE/docker-compose.yml"
sed -i "s|__DB_ROOT__|$DB_ROOT|g" "$BASE/docker-compose.yml"

echo ""
echo "✅ Client stack created: $CLIENT"
echo "➡ DNS: CNAME $DOMAIN → wpp1.justbots.tech"
echo "➡ Deploy:"
echo "docker compose -f $BASE/docker-compose.yml up -d"