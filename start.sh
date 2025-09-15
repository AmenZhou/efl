ps -ef | grep elixir | grep -v grep | awk '{print $2}' | xargs -r kill
PORT=4000 MIX_ENV=prod elixir --erl "-detached" -S mix phx.server

