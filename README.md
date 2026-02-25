# Crawler

This project is for a special usage on my own, more for fun. My first Elixir+Phoenix project.

## Quick Start

### Running Tests (Fast Development)
**Use optimized test scripts for development:**
```bash
./run_tests.sh                    # New optimized script with flexible options
./run_tests_fast.sh              # Fast script for basic test runs
```

These scripts use Docker volume mounting for instant test execution (2.5 seconds vs 30+ seconds for rebuilds) and ensure proper `MIX_ENV=test` environment.

### Alternative Test Methods
```bash
# Run specific test files
docker-compose exec -e MIX_ENV=test app mix test test/specific_file.exs

# Run tests with volume mounting (no rebuild needed)
docker-compose exec -e MIX_ENV=test app mix test

# If you see "dependency is not available, run mix deps.get": fetch test deps first
docker-compose exec -T -e MIX_ENV=test app mix deps.get
docker-compose exec -e MIX_ENV=test app mix test

# Interactive development
docker-compose exec app iex -S mix
```

### Development Workflow
1. Start containers: `docker-compose up -d`
2. Run tests: `./run_tests.sh` or `./run_tests_fast.sh`
3. Make code changes (reflected immediately)
4. Run tests again: `./run_tests.sh [specific_test_file]`

## Install on Ubuntu

`apt-get install build-essential`

#### Install asdf

[Reference](http://asdf-vm.com/guide/getting-started.html#_1-install-dependencies)

#### Install Elixir

`asdf plugin-add elixir`

`asdf install elixir 1.10.4`

#### Install Erlang
`asdf plugin-add erlang`

`asdf install erlang 22.3.4.20`

#### Set up mysql
`apt-get install mysql-server`

`CREATE USER 'hzhou'@'localhost'IDENTIFIED WITH mysql_native_password BY '';`
`GRANT ALL PRIVILEGES ON * . * TO 'hzhou'@'localhost';`

#### Create DB

`MIX_ENV=prod mix ecto.create`
`MIX_ENV=prod mix ecto.reset`

#### Seed
```
Efl.RefCategory.seeds
```

#### Proxy list import
To bulk-load proxies into the `proxies` table (source: [proxifly/free-proxy-list](https://github.com/proxifly/free-proxy-list?tab=readme-ov-file) — free HTTP/HTTPS/SOCKS list, updated every 5 min):

- **SQL file:** `priv/update_proxies.sql` (pre-generated; regenerate from the proxy list URL if needed).
- **Run via app (uses Repo DB config):** `mix run scripts/run_proxy_sql.exs`
- **Run via mysql client:** `mysql -u USER -p DATABASE < priv/update_proxies.sql` (or `sudo mysql DATABASE < priv/update_proxies.sql` where socket auth is used).
- **Verify:** `mix run scripts/verify_proxies.exs` — prints row count and latest 5 rows.

See `scripts/run_proxy_sql.exs` for inline documentation.

### Production automation tests (full DADI pipeline)
Same flow as `documents/manual_tests.ex` (delete Dadi, create_all_items, update_contents, create_xls, send email, proxy fetch, single-category run):

- **Script (prod DB):** `MIX_ENV=prod mix run scripts/production_smoke_test.exs`  
  Optional env: `PRODUCTION_SKIP_EMAIL=1` (skip sending email), `PRODUCTION_SINGLE_CATEGORY=1` (run single-category create_items after main steps).  
  Run when the web server is stopped to avoid port conflict, or from another host. For same-host runs without stopping the server, use: `EFL_SCRIPT_MODE=1 MIX_ENV=prod mix run scripts/production_smoke_test.exs` (skips starting the HTTP endpoint).
- **ExUnit (test DB, real HTTP):** `mix test test/integration/production_flow_test.exs --include production:true`  
  Production-tagged tests are excluded by default; use `--include production:true` to run them.

See `scripts/production_smoke_test.exs` and `test/integration/production_flow_test.exs` for details.

## Production Commands

### Server Management
```bash
# Start server in background
./server_manager.sh start

# Stop server
./server_manager.sh stop

# Restart server
./server_manager.sh restart

# Check server status
./server_manager.sh status

# View server logs
./server_manager.sh logs
```

### Data Fetching
```bash
# Trigger data fetching process (scrapes website and updates database)
wget http://localhost:4000/dadi/scratch > /dev/null 2>&1
```

### Email Testing
```bash
# Test email functionality
MIX_ENV=prod mix run test_email_simple.exs

# Test with full Excel generation
MIX_ENV=prod mix run test_prod_email.exs
```

### Application Testing
```bash
# Run all tests
./run_tests_fast.sh

# Run specific test
MIX_ENV=prod mix test test/specific_file.exs
```
