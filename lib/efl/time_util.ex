defmodule Efl.TimeUtil do
  def target_date do
    yesterday
  end

  def yesterday do
    Timex.local
    |> Timex.shift(days: -1)
    |> Timex.to_date
  end

  def today do
    Timex.local
    |> Timex.to_date
  end
end
