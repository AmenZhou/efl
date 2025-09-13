ps -ef | grep elixir | grep -v grep | awk '{print $2}' | xargs kill
MIX_ENV=prod elixir --erl "-detached" -S mix phx.server

