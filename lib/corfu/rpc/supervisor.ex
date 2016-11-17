defmodule Corfu.Rpc.Supervisor do
  use Supervisor
  require Logger
  @name __MODULE__

  def start_link() do
    Supervisor.start_link(__MODULE__, :ok, name: @name)
  end

  def init(:ok) do
    children = [
      worker(Corfu.Rpc.Node, [], restart: :transient)
    ]
    supervise(children, strategy: :simple_one_for_one)
  end

  # Client API
  def connect(nodes) do
    nodes |> Enum.reduce(%{}, fn(node, ret) ->
      Map.put(ret, node, connect_to(node))
    end)
  end

  def rpc(rpc_nodes, line) do
    rpc_nodes
    |> Map.values()
    |> Enum.map(fn(pid) ->
      GenServer.call(pid, {:cmd, line})
    end)
  end

  #Impl
  defp connect_to(node) do
    {:ok, _pid, name} = Supervisor.start_child(@name, [node])
    name
  end


end
