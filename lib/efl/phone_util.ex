defmodule Efl.PhoneUtil do
  #Find and fetch the first phone number in the content
  def find_phone_from_content(content) do
    ~r/(?<area_code>\d{3}).?(?<middle>\d{3}).?(?<last>\d{4})/
    |> Regex.named_captures(content)
    |> generate_phone_from_regex
  end

  defp generate_phone_from_regex(nil), do: nil

  #The arg is a map %{"area_code" => "222", "middle" => "222", "last" => "2222"}
  defp generate_phone_from_regex(regex) do
    Map.get(regex, "area_code")
    <> "-"
    <> Map.get(regex, "middle")
    <> "-"
    <> Map.get(regex, "last")
  end
end
