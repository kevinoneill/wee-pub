defmodule WeePubTest.Subscriber do
  use ExUnit.Case, async: true

  alias WeePub.{Broadcaster, Subscriber}

  defmodule TestSubscriber do
      use Subscriber

      subscribe %{id: id, age: age} = message, where: age > 16 and id != 1 do
        {"%{id: id, age: age} = message, where: age > 16 and id != 1", message}
      end

      subscribe %{id: id} = message, where: id == 1 do
        {"%{id: id} = message, where: id == 1", message}
      end

      subscribe(%{id: _} = message) do
        {"%{id: _} = message", message}
      end

      subscribe(message) do
        {"message", message}
      end

      def handle_call(:state, _caller, state) do
        {:reply, state, state}
      end

      def state do
        GenServer.call(TestSubscriber, :state)
      end

  end

  defp assert_state(state) do
    assert state == TestSubscriber.state
  end

  defp publish(message) do
    :ok = Broadcaster.publish(message)
  end

  setup do
    {:ok, subscriber} = start_supervised(TestSubscriber)
    %{subscriber: subscriber}
  end

  describe "filtered subscriptions" do

    test "it can recieve unfiltered messages" do
      publish("hello")
      assert_state {"message", "hello"}
    end

    test "it can recieve messages filtered by structure" do
      publish(%{id: 42})
      assert_state {"%{id: _} = message", %{id: 42}}
    end

    test "it can recieve messages filtered by simple where condition" do
      publish(%{id: 1})
      assert_state {"%{id: id} = message, where: id == 1", %{id: 1}}
    end

    test "it can recieve messages filtered by complex where condition" do
      publish(%{id: 6, age: 18})
      assert_state {"%{id: id, age: age} = message, where: age > 16 and id != 1", %{id: 6, age: 18}}
    end
  end

end
