<?php
// Performance
define('WP_CACHE', true);
define('WP_REDIS_HOST', 'redis');
define('WP_REDIS_PORT', 6379);
define('WP_REDIS_TIMEOUT', 1);
define('WP_REDIS_READ_TIMEOUT', 1);

// Disable cron (handled externally later)
define('DISABLE_WP_CRON', true);

// Reduce autosave overhead
define('AUTOSAVE_INTERVAL', 300);
define('WP_POST_REVISIONS', 5);

// Object cache key salt (per client)
define('WP_CACHE_KEY_SALT', '__CLIENT__');

// Memory (safe defaults)
define('WP_MEMORY_LIMIT', '256M');
define('WP_MAX_MEMORY_LIMIT', '256M');

// Security hardening
define('DISALLOW_FILE_EDIT', true);
define('FORCE_SSL_ADMIN', false); // ingress will handle later

// PHP optimizations
@ini_set('display_errors', 0);
@ini_set('max_execution_time', 60);