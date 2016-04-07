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
        pid = take_group_member(:riak, 500)
        result = unquote(name)(pid, unquote_splicing(other_args))
        :pooler.return_group_member(:riak, pid, :ok)
        result
      end
    end
  end

  def take_group_member(group_name, timeout \\ 100)
  def take_group_member(_, timeout) when timeout <= 0 do
    :error_no_members
  end
  def take_group_member(group_name, timeout) do
    case :pooler.take_group_member(group_name) do
      :error_no_members ->
        #should probably log a warning / error here so the operator knows something is wrong
        :timer.sleep(100)
        take_group_member(group_name, timeout - 100)
        pid -> pid
    end
  end

  defp extract_guards({:when, _, [left, right]}), do: {left, extract_or_guards(right)}
  defp extract_guards(else_), do: {else_, []}
  defp extract_or_guards({:when, _, [left, right]}), do: [left|extract_or_guards(right)];
  defp extract_or_guards(term), do: [term]

end
