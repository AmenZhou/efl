-- Generated from proxies.txt (protocol://ip:port lines).
-- Table: proxies (ip, port, inserted_at, updated_at, score)
-- Run: mysql -u USER -p DATABASE < priv/update_proxies.sql
-- 5 rows

DELETE FROM proxies;

INSERT INTO proxies (ip, port, inserted_at, updated_at, score) VALUES
('150.136.163.51', '80', NOW(), NOW(), 10),
('5.161.155.252', '80', NOW(), NOW(), 10),
('107.174.231.218', '8888', NOW(), NOW(), 10),
('137.184.96.68', '80', NOW(), NOW(), 10),
('174.138.119.88', '80', NOW(), NOW(), 10);
