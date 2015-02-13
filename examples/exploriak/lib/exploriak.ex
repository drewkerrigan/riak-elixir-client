defmodule Exploriak do

  def main(args) do
    args |> parse_args |> process
  end

  def parse_args(args) do
    switches =
      [
       help: :boolean,
       list: :boolean,
       keys: :boolean,
       bucket: :string
      ]

    options = OptionParser.parse(args, switches: switches)

    case options do
      {[help: true],_,_} -> :help
      {[buckets: true],_,_} -> [:list_buckets]
      {[buckets: true, keys: true],_,_} -> [:list_all_keys]
      {[buckets: true, keys: true, buckets: bucket],_,_} -> [:list_keys, bucket]
      _ -> :help
    end
  end

  def process(:help) do
    IO.puts """
      Usage:
        ./exploriak -s server_name [-n nickname]
      Options:
        --help      # Show this help message and quit.
      Listing:
        --list      # (boolean) List keys or buckets
       Selectors: 
        --type      # (string) Bucket type 
        --bucket    # (string) Bucket
        --keys      # (boolean) Use to list the keys
       bucket: :string
    """
    System.halt(0)
  end

  def process([:list_buckets]) do
    {:ok, pid} = connect
    for bucket <- Riak.Bucket.list!(pid) do
      IO.puts ["Bucket: ", bucket]
    end
  end

  def process([:list_keys, bucket]) do
    {:ok, pid} = connect
    for key <- Riak.Bucket.keys!(pid, bucket) do
      IO.puts ["Bucket: ", bucket, "Key: ", key]
    end
  end

  def process([:list_all_keys]) do
    {:ok, pid} = connect
    for bucket <- Riak.Bucket.list!(pid), key <- Riak.Bucket.keys!(pid, bucket) do
      IO.puts ["Bucket: ", bucket, "Key: ", key]
    end
  end

  

  defp connect do
    {:ok, pid } = Riak.Connection.start('127.0.0.1', 8087)    
    {:ok, pid}
  end
end
