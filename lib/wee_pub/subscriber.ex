defmodule WeePub.Subscriber.Filter do
  defmacro filter(pattern) do
    quote do
      fn (message) ->
        case message do
          unquote(pattern) -> true
          _ -> false
        end
      end
    end
  end
end

defmodule WeePub.Subscriber do
  import __MODULE__.Filter

  defmacro __using__(_options) do
    quote do
      @module __MODULE__

      import unquote(__MODULE__)

      Module.register_attribute @module, :subscriptions, accumulate: true
      @before_compile unquote(__MODULE__)

      use GenServer

      def child_spec(options) do
        %{
          id: @module,
          start: { @module, :start, [options]},
          type: :worker,
        }
      end

      def start(options \\ []) do
        GenServer.start_link(@module, nil, name: @module)
      end

      def init(state \\ nil) do
        register_subscriptions()

        {:ok, state}
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def register_subscriptions do
        for subscription <- @subscriptions do
          case subscription do
            [pattern: pattern, where: where] ->
              WeePub.Broadcaster.subscribe filter: filter(pattern when where)
            [pattern: pattern] ->
              WeePub.Broadcaster.subscribe filter: filter(pattern)
          end
        end
      end
    end
  end

  defmacro subscribe(pattern, do: block) do
    quote do
      @subscriptions [pattern: unquote(Macro.escape(pattern))]
      def handle_cast(unquote(pattern), state) do
        state = (unquote(block))
        {:noreply, state}
      end
    end
  end

  defmacro subscribe(pattern, [where: where], do: block) do
    quote do
      @subscriptions [pattern: unquote(Macro.escape(pattern)), where: unquote(Macro.escape(where))]
      def handle_cast(unquote(pattern), state) when unquote(where) do
        state = (unquote(block))
        {:noreply, state}
      end
    end
  end

end
