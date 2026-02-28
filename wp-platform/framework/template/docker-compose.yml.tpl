services:
  mysql:
    image: mysql:8.0
    restart: always
    environment:
      MYSQL_DATABASE: wp
      MYSQL_USER: wp
      MYSQL_PASSWORD: __DB_PASS__
      MYSQL_ROOT_PASSWORD: __DB_ROOT__
    volumes:
      - ./data/mysql:/var/lib/mysql
    networks:
      - __CLIENT__-net

  redis:
    image: redis:7-alpine
    restart: always
    command: ["redis-server", "--save", "", "--appendonly", "no"]
    networks:
      - __CLIENT__-net

  wordpress:
    image: wordpress:php8.2-apache
    restart: always
    environment:
      WORDPRESS_DB_HOST: mysql
      WORDPRESS_DB_NAME: wp
      WORDPRESS_DB_USER: wp
      WORDPRESS_DB_PASSWORD: __DB_PASS__
      WORDPRESS_CONFIG_EXTRA: |
        require '/var/www/html/wp-config-extra.php';
    volumes:
      - ./data/wp:/var/www/html
      - ./wp-config-extra.php:/var/www/html/wp-config-extra.php
    networks:
      - __CLIENT__-net
      - proxy
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=proxy"
      - "traefik.http.routers.__CLIENT__.rule=Host(`__DOMAIN__`)"
      - "traefik.http.routers.__CLIENT__.entrypoints=websecure"
      - "traefik.http.routers.__CLIENT__.tls=true"
      - "traefik.http.routers.__CLIENT__.tls.certresolver=le"
      - "traefik.http.services.__CLIENT__.loadbalancer.server.port=80"
    depends_on:
      - mysql
      - redis

networks:
  __CLIENT__-net:
    driver: bridge
  proxy:
    external: true