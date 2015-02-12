defmodule Riak do
  use Riak.Client
  defmacro __using__(opts) do
    env     = Keyword.get(opts, :env)

    
    quote do
      @behaviour Riak
      @env unquote(env)


      if @env do
        def conf do
          conf(@env)
        end
        defoverridable conf: 0
      end

      def start_link do
        Riak.Supervisor.start_link()
        conf
      end


    end
  end

end
