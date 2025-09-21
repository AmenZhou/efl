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
docker-compose exec app mix test test/specific_file.exs

# Run tests with volume mounting (no rebuild needed)
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
