defmodule WeePub.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      WeePub.Broadcaster,
      {Registry, keys: :duplicate, name: WeePub.Registry},
    ]

    opts = [strategy: :one_for_one, name: WeePub.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
