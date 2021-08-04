defmodule Efl.Repo do
  use Ecto.Repo, otp_app: :efl, adapter: Ecto.Adapters.MyXQL
end
