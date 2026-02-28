server {
  listen 80;
  server_name __DOMAIN__;

  root /var/www/html;
  index index.php;

  location / {
    try_files $uri $uri/ /index.php?$args;
  }

  location ~ \.php$ {
    include fastcgi_params;
    fastcgi_pass __CLIENT__-wp:9000;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
  }

  location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg)$ {
    expires max;
    access_log off;
  }
}