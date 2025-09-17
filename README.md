# Crawler

This project is for a special usage on my own, more for fun. My first Elixir+Phoenix project.

## Quick Start

### Running Tests (Fast Development)
**Always use the fast test script for development:**
```bash
./run_tests_fast.sh
```

This script uses Docker volume mounting for instant test execution (2.5 seconds vs 30+ seconds for rebuilds).

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
2. Run tests: `./run_tests_fast.sh`
3. Make code changes (reflected immediately)
4. Run tests again: `./run_tests_fast.sh`

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
