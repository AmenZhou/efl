defmodule Efl.MyHttp do
  require IEx
  @api_rotator_url "http://falcon.proxyrotator.com:51337/?apiKey=U8CJ7jTmVtfry4dPWYFKXRsbqSnGo93c"

# HTTPotion.get('google.com', [
#     ibrowse: [proxy_host: '45.231.28.142', proxy_port: 8080],
#     timeout: 120_000
#   ])
  def request(url) do
    case call_proxy do
      { :ok, body } ->
        HTTPotion.get(url, proxy_config(body))
      { :error, message } ->
        { :error, message }
    end
  end

  def proxy_response(body) do
    body |> Poison.Parser.parse!
  end

  def call_proxy() do
    case HTTPotion.get(@api_rotator_url) do
      %{ body: body } ->
        { :ok, body }
      %{ message: message } ->
        { :error, message }
    end
  end

  def current_proxy_ip(body) do
    case body |> proxy_response do
      %{ "ip" => ip_str } ->
        String.to_charlist(ip_str)
      _ ->
        raise("Can not get proxy ip address")
    end
  end

  def current_proxy_port(body) do
    case body |> proxy_response do
      %{ "port" => port_str } ->
        { port_int, _ } = Integer.parse(port_str)
        port_int
      _ ->
        raise("Can not get proxy port")
    end
  end

  def proxy_config(body) do
    [ ibrowse: [ proxy_host: current_proxy_ip(body), proxy_port: current_proxy_port(body) ] ]
  end
end