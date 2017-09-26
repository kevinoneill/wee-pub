defmodule WeePub.Broadcaster do
  @moduledoc """
  A `GenServer` that manages distribution of messages to interested clients
  """

  use GenServer

  @broadcaster __MODULE__
  @registry WeePub.Registry
  @topic @broadcaster

  @doc false
  def child_spec(options) do
    %{
      id: @broadcaster,
      start: {__MODULE__, :start, [options]},
      type: :worker,
    }
  end

  @doc false
  def start(options \\ []) do
    GenServer.start_link(__MODULE__, options, name: @broadcaster)
  end

  @doc false
  def init(_options) do
    {:ok, %{}}
  end

  @doc """
  Registers the caller process as a subscriber to broadcasts.

  **Options**

  * `filter:` A function that accepts a single parameter and returns a boolean.
              Defaults to all messages

  * `topic:` A narrow cast topic atom. The subscriber's filter will only be evaluated
             if the topic matches the topic registered with. **Note:** `WeePub.Subscriber`
             does not currently support generating clients with narrow cast topics.
  """
  def subscribe(options \\ []) do
    options = Keyword.merge [topic: @topic, filter: (fn _ -> true end)], options

    Registry.register(
      @registry,
      options[:topic],
      %{filter: options[:filter]}
    )
  end

  @doc """
  Publish a message

  * `message` The message to be sent to subscribers if their `filter:` matches

  **Options**

  * `topic:` A narrow cast topic atom. The message will only be evaluated for subscribers
             registered with a matching topic registration. **Note:** `WeePub.Subscriber`
             does not currently support generating clients with narrow cast topics.

  """
  def publish(message, options \\ []) do
    options = Keyword.merge [topic: @topic], options
    GenServer.call(@broadcaster, {:publish, %{message: message, topic: options[:topic]}})
  end

  @doc false
  def handle_call({:publish, %{message: _, topic: _} = message}, _caller, state) do
    {:reply, broadcast(message), state}
  end

  defp broadcast(%{message: message, topic: topic}) do
    Registry.dispatch(@registry, topic, &propagate(message, &1), parallel: true)
  end

  defp propagate(message, entries) do
    stream = entries
      |> Stream.map(fn ({pid, %{filter: filter}}) -> {pid, filter} end)
      |> Stream.filter(&divulge?(&1, message))
      |> Stream.map(&divulge(&1, message))

    Stream.run(stream)
  end

  defp divulge?({_, filter}, message) do
    filter.(message)
  end

  defp divulge({pid, _}, message) do
    GenServer.cast(pid, message)
  end

end
