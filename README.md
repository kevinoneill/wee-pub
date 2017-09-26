# WeePub

[![License](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

WeePub is a light weight publish/subscribe system built on the elixir
[Registry](https://hexdocs.pm/elixir/master/Registry.html).

```elixir
defmodule TestSubscriber do
  use WeePub.Subscriber

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
```

## Features

- [x] Broadcast messages
- [x] Narrow cast messages to specific a topic
- [x] Subscribe to Broadcast messages using match expressions
- [ ] Subscribe to Narrow cast messages using match expressions
- [x] Subscriber implicit state handling
- [ ] Subscriber explicit state handling
- [ ] Allow generated `GenServer` methods to be overridden
- [ ] Specs for all interfaces
- [x] Docs for all important methods

## Summary

### `WeePub.Broadcaster`

`WeePub.Broadcaster` has two simple methods, `subscribe` to register subscribers, and
`publish` to publish messages.

Registration is handled automatically when `WeePub.Subscriber` is used
but any `GenServer` can be registered to receive messages.

### `WeePub.Subscriber`

By using `WeePub.Subscriber` your module will be created as a `GenServer` with 
default `child_spec`, `start` and `init` methods.

The `subscribe` macro will create a `handle_cast` method pattern matched to the 
subscription and will register the Module and pattern with `WeePub.Broadcaster`.

Like any pattern matching order of declaration is important.

`subscribe any do …` will intercept calls to more specific version e.g.
`subscribe %{id: _} …` if higher up in the file.

**Note:** Messages are `cast` to subscribers, meaning there is no acknowledgement of receipt. This is not meant to be used as reliable delivery messaging system.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `weepub` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:weepub, "~> 0.1.0"}
  ]
end
```

## `where:` vs `when`

I would have liked not to have the `where:` keyword parameter and instead
just used a `when` clause (which is what the `where:` parameter is transformed
into). Unfortunately my conjuring of macro constructs failed to give me a
reliable result. 
