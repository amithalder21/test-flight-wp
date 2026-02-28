services:
  mysql:
    image: mysql:8.0
    container_name: __CLIENT__-mysql
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
    image: redis:7
    container_name: __CLIENT__-redis
    restart: always
    volumes:
      - ./data/redis:/data
    networks:
      - __CLIENT__-net

  wordpress:
    image: wordpress:php8.2-fpm
    container_name: __CLIENT__-wp
    restart: always
    environment:
      WORDPRESS_DB_HOST: mysql
      WORDPRESS_DB_NAME: wp
      WORDPRESS_DB_USER: wp
      WORDPRESS_DB_PASSWORD: __DB_PASS__
      WORDPRESS_CONFIG_EXTRA: |
        define('WP_HOME', 'https://__DOMAIN__');
        define('WP_SITEURL', 'https://__DOMAIN__');
        define('WP_CACHE', true);
        define('WP_REDIS_HOST', 'redis');
        define('DISABLE_WP_CRON', true);
    volumes:
      - ./data/wp:/var/www/html
    networks:
      - __CLIENT__-net
    depends_on:
      - mysql
      - redis

  nginx:
    image: nginx:alpine
    container_name: __CLIENT__-nginx
    restart: always
    volumes:
      - ./data/wp:/var/www/html
      - ./nginx.conf:/etc/nginx/conf.d/default.conf
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=ingress"
      - "traefik.http.routers.__CLIENT__.rule=Host(`__DOMAIN__`)"
      - "traefik.http.routers.__CLIENT__.entrypoints=web"
      - "traefik.http.services.__CLIENT__.loadbalancer.server.port=80"
    networks:
      - __CLIENT__-net
      - ingress
    depends_on:
      - wordpress

networks:
  __CLIENT__-net:
    driver: bridge
  ingress:
    external: true