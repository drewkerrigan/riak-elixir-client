defmodule RiakExplorer do

  def main(args) do
    args |> parse_args |> process
  end

  def parse_args(args) do
    switches =
      [
       help: :boolean,
       list: :boolean,
       type: :string,
       bucket: :string
      ]

    aliases =
      [
       h: :help,
       l: :list,
       t: :type,
       b: :bucket
      ]

    options = OptionParser.parse(args, switches: switches, aliases: aliases)

    case options do
      { [ help: true
          ], _, _} -> :help
      { [ list: true
          ], _, _} -> [:list_buckets]
      { [ list: true, 
          bucket: bucket
          ], _, _} -> [:list_keys, bucket]
      { [ list: true, 
          type: type
          ], _, _} -> [:list_buckets, type]
      { [ list: true, 
          type: type, 
          bucket: bucket
          ], _, _} -> [:list_keys, type, bucket]
      _ -> []
    end
  end

  def process(:help) do
    IO.puts """
      Usage:
        ./riak_explorer -s server_name [-n nickname]
      Options:
        -h, [--help]      # Show this help message and quit.
        -l, [--list]      # List keys or buckets (boolean)
        -t, [--type]      # Bucket type (optional string)
        -b, [--bucket]      # Bucket (optional string)
       bucket: :string
    """
    System.halt(0)
  end

  def process([]) do
    process([nil, nil])
  end

  def process([:list_buckets]) do

  end

  def process([:list_keys, bucket]) do

  end

  def process([:list_buckets, type]) do

  end

  def process([:list_keys, type, bucket]) do

  end
end
