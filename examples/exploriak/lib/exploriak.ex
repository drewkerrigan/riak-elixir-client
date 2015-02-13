defmodule Exploriak do

  def main(args) do
    args |> parse_args |> process
  end

  def parse_args(args) do
    switches =
      [
       help: :boolean,
       ## List
       list: :boolean,
       keys: :boolean,
       type: :string,
       bucket: :string
      ]

    options = OptionParser.parse(args, switches: switches)

    case options do
      {[help: true],_,_} -> :help
      ## List
      {[list: true],_,_} -> [:list_buckets]
      {[list: true, type: type],_,_} -> [:list_buckets, type]
      {[list: true, keys: true],_,_} -> [:list_keys]
      {[list: true, keys: true, bucket: bucket],_,_} -> [:list_keys, bucket]
      {[list: true, keys: true, type: type, bucket: bucket],_,_} -> [:list_keys, type, bucket]
      _ -> :help
    end
  end

  def process(:help) do
    IO.puts """
      Usage:
        ./exploriak [operation] [options]
      Options:
        --help      # Show this help message and quit.
      Listing:
        --list      # (boolean) List keys or buckets
        --keys      # (boolean) If not used, only buckets will be listed
       Selectors: 
        --type      # (string) Bucket type
        --bucket    # (string) Bucket

      Examples:
        ./exploriak --list # List all buckets in default bucket type
        ./exploriak --list --type mytype # List all buckets in mytype bucket type
        ./exploriak --list --keys --bucket mybucket # List all keys in default bucket type, mybucket

    """
    System.halt(0)
  end

  ## List
  def process([:list_buckets]) do
    IO.puts "Listing all buckets in default type"
    for bucket <- Riak.Bucket.list!(get_pid) do
      IO.puts ["Bucket: ", bucket]
    end
  end

  def process([:list_buckets, type]) do
    IO.puts "Listing all buckets in default type"
    for bucket <- Riak.Bucket.Type.list!(get_pid, type) do
      IO.puts ["Bucket: ", bucket]
    end
  end

  def process([:list_keys, bucket]) do
    IO.puts ["Listing all keys in default type, ", bucket, " bucket"]
    for key <- Riak.Bucket.keys!(get_pid, bucket) do
      IO.puts ["Bucket: ", bucket, ", Key: ", key]
    end
  end

  def process([:list_keys, type, bucket]) do
    IO.puts ["Listing all keys in ", type, " type, ", bucket, " bucket"]
    for key <- Riak.Bucket.Type.keys!(get_pid, type, bucket) do
      IO.puts ["Bucket: ", bucket, ", Key: ", key]
    end
  end

  def process([:list_keys]) do
    IO.puts ["Listing all keys in default type, all buckets"]
    for bucket <- Riak.Bucket.list!(get_pid), key <- Riak.Bucket.keys!(get_pid, bucket) do
      IO.puts ["Bucket: ", bucket, ", Key: ", key]
    end
  end

  defp get_pid do
    {:ok, pid } = Riak.Connection.start('127.0.0.1', 8087)    
    pid
  end
end
