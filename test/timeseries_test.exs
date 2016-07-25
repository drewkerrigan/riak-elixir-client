defmodule Riak.TimeseriesTest do
  use Riak.Case
  alias Riak.Timeseries

  @moduletag :riakts

  test "Insert TS records and query them" do
    assert :ok == Timeseries.put("GeoCheckin", [
          {"region1", "state1", 25, "hot", 23.0},
          {"region2", "state99", 26, "windy", 19.0}
        ])

    e1 = {["region", "state", "time", "weather", "temperature"], [{"region1", "state1", 25, "hot", 23.0}]}
    r1 = Timeseries.query("select * from GeoCheckin where time > 24 and time < 26 and region = 'region1' and state = 'state1'")

    e2 = {["region", "state", "time", "weather", "temperature"],
          [{"region2", "state99", 26, "windy", 19.0}]}
    r2 = Timeseries.query("select * from GeoCheckin where time > 25 and time < 27 and region = 'region2' and state = 'state99'")

    r3_results = Timeseries.list!("GeoCheckin")
    r3 = contains_row(
      r3_results, {"region1", "state1", 25}) or contains_row(
      r3_results, {"region2", "state99", 26})
    e3 = true

    e4 = {["region", "state", "time", "weather", "temperature"],
          [{"region1", "state1", 25, "hot", 23.0}]}
    r4 = Timeseries.get("GeoCheckin", ["region1", "state1", 25])

    e5 = {["region", "state", "time", "weather", "temperature"],
          [{"region2", "state99", 26, "windy", 19.0}]}
    r5 = Timeseries.get("GeoCheckin", ["region2", "state99", 26])

    e6 = :ok
    r6 = Timeseries.delete("GeoCheckin", ["region1", "state1", 25])

    e7 = :ok
    r7 = Timeseries.delete("GeoCheckin", ["region2", "state99", 26])

    e8 = {[], []}
    r8 = Timeseries.get("GeoCheckin", ["region1", "state1", 25])

    e9 = {[], []}
    r9 = Timeseries.get("GeoCheckin", ["region2", "state99", 26])

    e10 = {[],[]}
    r10 = Timeseries.query("select * from GeoCheckin where time > 25 and time < 27 and region = 'region2' and state = 'state99'")

    assert e1 == r1
    assert e2 == r2
    assert e3 == r3
    assert e4 == r4
    assert e5 == r5
    assert e6 == r6
    assert e7 == r7
    assert e8 == r8
    assert e9 == r9
    assert e10 == r10
  end

  defp contains_row([_], _) do
    false
  end
  defp contains_row([row|_], row) do
    true
  end
  defp contains_row([_|rest], row) do
    contains_row(rest, row)
  end
end
