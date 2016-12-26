defmodule Efl.TimeUtil do
  def yesterday_date do
    yesterday_datetime
    |> Timex.to_date
  end

  def yesterday_datetime do
    Timex.now
    |> Timex.local
    |> Timex.shift(days: -1)
  end
end
