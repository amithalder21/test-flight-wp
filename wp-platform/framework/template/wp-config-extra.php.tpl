<?php
/**
 * Platform-controlled WordPress configuration
 * Loaded before WordPress core bootstraps
 */

/* -------------------------------------------------
 * Reverse proxy / HTTPS awareness (Traefik / CF)
 * ------------------------------------------------- */
if (
    isset($_SERVER['HTTP_X_FORWARDED_PROTO']) &&
    $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https'
) {
    $_SERVER['HTTPS'] = 'on';
}

/* -------------------------------------------------
 * Object Cache (Redis)
 * ------------------------------------------------- */
define('WP_CACHE', true);

define('WP_REDIS_HOST', 'redis');
define('WP_REDIS_PORT', 6379);
define('WP_REDIS_DATABASE', 0);
define('WP_REDIS_TIMEOUT', 1);
define('WP_REDIS_READ_TIMEOUT', 1);
define('WP_REDIS_MAXTTL', 86400);

/* Cache isolation per client */
define('WP_CACHE_KEY_SALT', '__CLIENT__:v1');

/* -------------------------------------------------
 * Cron & Background Work
 * ------------------------------------------------- */
define('DISABLE_WP_CRON', true);

/* -------------------------------------------------
 * Reduce DB & Admin Overhead
 * ------------------------------------------------- */
define('AUTOSAVE_INTERVAL', 300);
define('WP_POST_REVISIONS', 5);

/* -------------------------------------------------
 * Security & Admin Safety
 * ------------------------------------------------- */
define('XMLRPC_REQUEST', false);
define('COOKIE_DOMAIN', $_SERVER['HTTP_HOST']);

/* -------------------------------------------------
 * PHP Runtime Safety
 * ------------------------------------------------- */
@ini_set('display_errors', 0);
@ini_set('max_execution_time', 60);

/* -------------------------------------------------
 * OPTIONAL — Enable ONLY if sessions are required
 * (WooCommerce, LMS, Membership)
 * ------------------------------------------------- */
/*
ini_set('session.save_handler', 'redis');
ini_set('session.save_path', 'tcp://redis:6379?database=2');

ini_set('redis.session.prefix', '__CLIENT__:sess:');
ini_set('redis.session.locking_enabled', 1);
ini_set('redis.session.lock_retries', 10);
ini_set('redis.session.lock_wait_time', 2000);
*/