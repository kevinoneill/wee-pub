defmodule WeePub.Broadcaster do
  use GenServer

  @broadcaster __MODULE__
  @registry WeePub.Registry
  @topic @broadcaster

  def child_spec(options) do
    %{
      id: @broadcaster,
      start: {__MODULE__, :start, [options]},
      type: :worker,
    }
  end

  def start(options \\ []) do
    GenServer.start_link(__MODULE__, options, name: @broadcaster)
  end

  def init(_options) do
    {:ok, %{}}
  end

  def publish(message, options \\ []) do
    options = Keyword.merge [topic: @topic], options
    GenServer.call(@broadcaster, {:publish, %{message: message, topic: options[:topic]}})
  end

  def subscribe(options \\ []) do
    options = Keyword.merge [topic: @topic, filter: (fn _ -> true end)], options

    Registry.register(
      @registry,
      options[:topic],
      %{filter: options[:filter]}
    )
  end

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
