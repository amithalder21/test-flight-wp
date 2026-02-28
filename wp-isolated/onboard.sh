#!/bin/bash
set -e

echo "🚀 Fully Isolated WordPress Onboarding"

read -p "Client name (short id): " CLIENT
read -p "Domain (e.g. www.client.com): " DOMAIN
read -p "Local port (unique, e.g. 8085): " PORT
read -s -p "DB password: " DB_PASS
echo ""
read -s -p "DB root password: " DB_ROOT
echo ""

BASE="clients/$CLIENT"
mkdir -p $BASE/data/{wp,mysql,redis}

cp template/docker-compose.yml.tpl $BASE/docker-compose.yml
cp template/nginx.conf.tpl $BASE/nginx.conf

sed -i "s/__CLIENT__/$CLIENT/g" $BASE/docker-compose.yml $BASE/nginx.conf
sed -i "s/__DOMAIN__/$DOMAIN/g" $BASE/docker-compose.yml $BASE/nginx.conf
sed -i "s/__PORT__/$PORT/g" $BASE/docker-compose.yml
sed -i "s/__DB_PASS__/$DB_PASS/g" $BASE/docker-compose.yml
sed -i "s/__DB_ROOT__/$DB_ROOT/g" $BASE/docker-compose.yml

echo ""
echo "✅ Client stack created: $CLIENT"
echo "➡ Deploy with:"
echo "docker compose -f $BASE/docker-compose.yml up -d"