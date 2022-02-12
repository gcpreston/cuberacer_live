defmodule CuberacerLive.CountryUtilsTest do
  use ExUnit.Case, async: true

  import CuberacerLive.CountryUtils

  describe "to_flag_emoji/1" do
    test "converts to flag emoji" do
      assert to_flag_emoji("GB") == "🇬🇧"
      assert to_flag_emoji("EC") == "🇪🇨"
    end

    test "is case-insensitive" do
      assert to_flag_emoji("kh") == "🇰🇭"
      assert to_flag_emoji("hK") == "🇭🇰"
      assert to_flag_emoji("Cz") == "🇨🇿"
    end

    test "doesn't break on non-country codes" do
      assert to_flag_emoji("BX") == "🇧🇽"
    end

    test "only accepts alphabet strings of length 2" do
      assert to_flag_emoji("toolong") == nil
      assert to_flag_emoji("a1") == nil
      assert to_flag_emoji("*t") == nil
    end
  end
end
