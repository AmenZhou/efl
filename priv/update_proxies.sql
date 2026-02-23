-- Proxy list source: https://github.com/proxifly/free-proxy-list (README has direct download links).
-- This SQL was generated from the HTTPS proxies list (e.g. .txt via jsdelivr); regenerate by
-- fetching that list, parsing "protocol://ip:port" lines into (ip, port), then batching INSERTs.
-- Table: proxies (ip, port, inserted_at, updated_at, score)
-- Run: mysql -u USER -p DATABASE < priv/update_proxies.sql
-- 674 rows

INSERT INTO proxies (ip, port, inserted_at, updated_at, score) VALUES
