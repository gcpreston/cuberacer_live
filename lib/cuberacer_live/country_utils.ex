defmodule CuberacerLive.CountryUtils do
  @regional_indicator_offset 127_397
  @alphabet_code_point_range ?A..?Z

  @doc """
  Convert an ISO 3166-1 alpha-2 country code to its corresponding flag emoji.
  This function is case-insensitive.

  It works by converting the characters to their regional indicator symbols,
  which, when concatenated, display as a flag emoji. However, because of this,
  it is possible to pass a 2-character combo which has no corresponding flag
  emoji.

  If a string is passed which is not length 2 containing latin alphabet
  characters, `nil` is returned.

  ## Examples

      iex> to_flag_emoji("US")
      "🇺🇸"

      iex> to_flag_emoji("ar")
      "🇦🇷"

      iex> to_flag_emoji("XB")
      "🇽🇧"

      iex> to_flag_emoji("hello")
      nil

      iex> to_flag_emoji("A$")
      nil

  """
  def to_flag_emoji(country_code) when is_binary(country_code) do
    if String.length(country_code) != 2 do
      nil
    else
      [code1, code2] = country_code |> String.upcase() |> String.to_charlist()

      if code1 not in @alphabet_code_point_range or code2 not in @alphabet_code_point_range do
        nil
      else
        <<code1 + @regional_indicator_offset::utf8>> <>
          <<code2 + @regional_indicator_offset::utf8>>
      end
    end
  end
end
