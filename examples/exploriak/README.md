Exploriak
============

A simple Elixir CLI app to perform a few actions against a local Riak node.

## Build

```
make
```

## Usage

Output of `./exploriak --help`:

```
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
```