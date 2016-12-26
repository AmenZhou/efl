defmodule Efl.TimeUtil do
  def yesterday do
    Timex.now
    |> Timex.local
    |> Timex.to_date
    |> Timex.shift(days: -1)
  end
end
