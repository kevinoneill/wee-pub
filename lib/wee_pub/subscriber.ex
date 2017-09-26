defmodule WeePub.Subscriber.Filter do
  @moduledoc false

  @doc """
  Captures a pattern and turns it into a filter function
  """
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
  @moduledoc """
  Creates a `GenServer` that registers subscriptions with `WeePub.Broadcaster`
  """
  import __MODULE__.Filter
  alias WeePub.Broadcaster

  @doc false
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
          start: {@module, :start, [options]},
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

  @doc false
  defmacro __before_compile__(_env) do
    quote do
      def register_subscriptions do
        for subscription <- @subscriptions do
          case subscription do
            [pattern: pattern, where: where] ->
              Broadcaster.subscribe filter: filter(pattern when where)
            [pattern: pattern] ->
              Broadcaster.subscribe filter: filter(pattern)
          end
        end
      end
    end
  end

  @doc """
  Creates a `handle_cast` function that will accept messages matching the
  pattern and the `where:` clause if present.

  **Note:** The GenServer state is implicitly set to the result of the
  body of the macro.

  ```
  subscribe %{id, id} = message, where: id = 42 do
    ... processes the message
  end
  ```
  will be transformed to
  ```
  def handle_cast(%{id, id} = message, state) when id = 42 do
    state = ... process the message
    {:noreply, state}
  end

  and the pattern and Module will be registered with `WeePub.Broadcaster`

  The `where:` clause is optional but when included needs to obey the
  same restrictions as a `when` guard clause.
  """
  defmacro subscribe(pattern, [where: where], do: block) do
    quote do
      @subscriptions [pattern: unquote(Macro.escape(pattern)), where: unquote(Macro.escape(where))]
      def handle_cast(unquote(pattern), state) when unquote(where) do
        state = (unquote(block))
        {:noreply, state}
      end
    end
  end

  @doc false
  defmacro subscribe(pattern, do: block) do
    quote do
      @subscriptions [pattern: unquote(Macro.escape(pattern))]
      def handle_cast(unquote(pattern), state) do
        state = (unquote(block))
        {:noreply, state}
      end
    end
  end

end
