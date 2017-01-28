defmodule Efl.EtsManager do
  @ets_table :dadi
  @ets_key :is_running

  #Todo move ets functions to an independent file
  def ets_create_table do
    try do
      :ets.new(@ets_table, [:set, :protected, :named_table])
    rescue
      _ -> IO.puts("The ets table exists!")
    end
  end

  def ets_insert(is_running) do
    try do
      :ets.insert(@ets_table, { @ets_key, is_running })
    rescue
      _ -> IO.puts("Ets insert fail")
    end
  end

  def ets_lookup do
    try do
      { @ets_key, value } = :ets.lookup(@ets_table, @ets_key) |> List.first
      value
    rescue
      _ -> false
    end
  end
end
