defmodule Riak.Pool do
  @moduledoc """
  [EXPERIMENTAL]
  This module adds defpool to define functions with a
  lower arity for each function so:

  Riak.put(pid, bucket, key, data) ->
  Riak.put(bucket, key, data) that calls the previous function
  with a pid from the pool
  """
  defmacro defpool(args, do: block) do
    {{name, _, args}, guards} = extract_guards(args)
    [_pid_arg | other_args] = args
    has_guards = (guards != [])
    quote do
      if unquote(has_guards) do
        def unquote(name)(unquote_splicing(args)) when unquote(hd(guards)) do
          unquote(block)
        end
      else
        def unquote(name)(unquote_splicing(args)) do
          unquote(block)
        end
      end
      def unquote(name)(unquote_splicing(other_args)) do
        pid = :pooler.take_group_member(:riak)
        result = unquote(name)(pid, unquote_splicing(other_args))
        :pooler.return_group_member(:riak, pid, :ok)
        result
      end
    end
  end

  defp extract_guards({:when, _, [left, right]}), do: {left, extract_or_guards(right)}
  defp extract_guards(else_), do: {else_, []}
  defp extract_or_guards({:when, _, [left, right]}), do: [left|extract_or_guards(right)];
  defp extract_or_guards(term), do: [term]
end
