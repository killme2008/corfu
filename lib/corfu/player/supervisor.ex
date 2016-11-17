defmodule Corfu.Player.Supervisor do
  use Supervisor
  require Logger

  def start_link(node, rpc_nodes) do
    Supervisor.start_link(__MODULE__, {node, rpc_nodes})
  end

  def init({node, rpc_nodes}) do
    children = [
      worker(Corfu.Player.Bookkeeper, []),
      worker(Corfu.Player.IdGenerator, [node]),
      worker(Corfu.Player.Proposer, [node, rpc_nodes]),
      worker(Corfu.Player.Acceptor, [node])
    ]
    supervise(children, strategy: :one_for_one)
  end

end
