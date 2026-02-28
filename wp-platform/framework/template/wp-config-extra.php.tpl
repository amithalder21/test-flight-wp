<?php
// Reverse proxy HTTPS awareness (MANDATORY)
if (
    isset($_SERVER['HTTP_X_FORWARDED_PROTO']) &&
    $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https'
) {
    $_SERVER['HTTPS'] = 'on';
}

// Performance
define('WP_CACHE', true);
define('WP_REDIS_HOST', 'redis');
define('WP_REDIS_PORT', 6379);
define('WP_REDIS_TIMEOUT', 1);
define('WP_REDIS_READ_TIMEOUT', 1);

// Disable WP cron (external later)
define('DISABLE_WP_CRON', true);

// Reduce overhead
define('AUTOSAVE_INTERVAL', 300);
define('WP_POST_REVISIONS', 5);

// Memory
define('WP_MEMORY_LIMIT', '256M');
define('WP_MAX_MEMORY_LIMIT', '256M');

// Security
define('DISALLOW_FILE_EDIT', true);
define('FORCE_SSL_ADMIN', false);

// PHP safety
@ini_set('display_errors', 0);
@ini_set('max_execution_time', 60);

// Cache key isolation
define('WP_CACHE_KEY_SALT', '__CLIENT__');