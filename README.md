# Crawler

This project is for a special usage on my own, more for fun. My first Elixir+Phoenix project.


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

#### Seed
```
Efl.RefCategory.seeds
```
