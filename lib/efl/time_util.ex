defmodule Efl.TimeUtil do
  #def target_date do
    #Agent.start_link(fn -> yesterday end, name: __MODULE__)
  #end

  def target_date do
    today
  end

  def yesterday do
    timezone = Timex.Timezone.get("America/New_York", Timex.now)

    Timex.Timezone.convert(Timex.now, timezone)
    |> Timex.shift(days: -1)
    |> Timex.to_date
  end

  def today do
    timezone = Timex.Timezone.get("America/New_York", Timex.now)

    Timex.Timezone.convert(Timex.now, timezone)
    |> Timex.to_date
  end
end
