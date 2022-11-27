defmodule CuberacerLive.ParticipantDataEntryTest do
  use CuberacerLive.DataCase, async: true

  alias CuberacerLive.ParticipantDataEntry

  import CuberacerLive.AccountsFixtures

  describe "new/1" do
    test "creates a struct with default values" do
      user = user_fixture()

      assert %ParticipantDataEntry{user: ^user, meta: %{solving: false, time_entry: :timer}} =
               ParticipantDataEntry.new(user)
    end
  end

  describe "solving" do
    setup do
      user = user_fixture()
      %{entry: ParticipantDataEntry.new(user)}
    end

    test "getter and setter work", %{entry: entry} do
      assert ParticipantDataEntry.get_solving(entry) == false

      entry = ParticipantDataEntry.set_solving(entry, true)
      assert ParticipantDataEntry.get_solving(entry) == true

      entry = ParticipantDataEntry.set_solving(entry, false)
      assert ParticipantDataEntry.get_solving(entry) == false
    end
  end

  describe "time_entry" do
    setup do
      user = user_fixture()
      %{entry: ParticipantDataEntry.new(user)}
    end

    test "getter and setter work", %{entry: entry} do
      assert ParticipantDataEntry.get_time_entry(entry) == :timer

      entry = ParticipantDataEntry.set_time_entry(entry, :keyboard)
      assert ParticipantDataEntry.get_time_entry(entry) == :keyboard

      entry = ParticipantDataEntry.set_time_entry(entry, :timer)
      assert ParticipantDataEntry.get_time_entry(entry) == :timer
    end
  end
end
