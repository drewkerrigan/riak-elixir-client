defmodule Riak.TimeseriesTest do
  use Riak.Case
  alias Riak.Timeseries

  @moduletag :riakts

  # Setup:
  # riak-admin bucket-type create GeoCheckin '{"props":{"n_val":3, "table_def":"CREATE TABLE GeoCheckin ( myfamily varchar not null, myseries varchar not null, time timestamp not null, weather varchar not null, temperature sint64, PRIMARY KEY ((myfamily, myseries, quantum(time, 15, ''m'')), myfamily, myseries, time))"}}'

  test "Insert TS records and query them" do
    Timeseries.put("GeoCheckin", [
          ["family1", "series1", 25, "hot", 23],
          ["family2", "series99", 26, "windy", 19]
        ])

    e1 = {["myfamily", "myseries", "time", "weather", "temperature"],
          [{"family1", "series1", 25, "hot", 23}]}
    r1 = Timeseries.query("select * from GeoCheckin where time > 24 and time < 26 and myfamily = 'family1' and myseries = 'series1'")

    e2 = {["myfamily", "myseries", "time", "weather", "temperature"],
          [{"family2", "series99", 26, "windy", 19}]}
    r2 = Timeseries.query("select * from GeoCheckin where time > 25 and time < 27 and myfamily = 'family2' and myseries = 'series99'")

    # e3 = {:ok, [{"family1", "series1", 25}, {"family2", "series99", 26}]}
    # r3 = Timeseries.list!("GeoCheckin")

    e4 = {:ok, {["myfamily", "myseries", "time", "weather", "temperature"],
                [["family1", "series1", 25, "hot", 23]]}}
    r4 = Timeseries.get("GeoCheckin", ["family1", "series1", 25])

    e5 = {:ok, {["myfamily", "myseries", "time", "weather", "temperature"],
                [["family2", "series99", 26, "windy", 19]]}}
    r5 = Timeseries.get("GeoCheckin", ["family2", "series99", 26])

    e6 = :ok
    r6 = Timeseries.delete("GeoCheckin", ["family1", "series1", 25])

    e7 = :ok
    r7 = Timeseries.delete("GeoCheckin", ["family2", "series99", 26])

    e8 = {:ok, {[], []}}
    r8 = Timeseries.get("GeoCheckin", ["family1", "series1", 25])

    e9 = {:ok, {[], []}}
    r9 = Timeseries.get("GeoCheckin", ["family2", "series99", 26])

    # e10 = {[],[]}
    # r10 = Timeseries.query("select * from GeoCheckin where time > 25 and time < 27 and myfamily = 'family2' and myseries = 'series99'")

    assert e1 == r1
    assert e2 == r2
    # assert e3 == r3
    assert e4 == r4
    assert e5 == r5
    assert e6 == r6
    assert e7 == r7
    assert e8 == r8
    assert e9 == r9
    # assert e10 == e10
  end
end
