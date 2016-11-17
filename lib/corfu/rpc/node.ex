defmodule Corfu.Rpc.Node do

  require Logger
  @reconnect_interval 1000

  defmodule State do
	  defstruct socket: nil, node: nil
  end

  use GenServer

  # Client API
  def start_link(%{host: host, port: port}=node) do
    name = String.to_atom("#{host}:#{port}")
    {:ok ,pid } = GenServer.start_link(__MODULE__, node, name: name)
    {:ok, pid, name}
  end

  def rpc(cmd) do
    GenServer.call(__MODULE__, {:cmd, cmd})
  end

  # Server callbacks
  def init(node) do
    connect(node)
  end

  def handle_call({:cmd, cmd}, _from, %State{socket: socket, node: _node}=state) do
    if socket do
      :gen_tcp.send(socket, cmd)
      {:ok, data} = :gen_tcp.recv(socket, 0)
      {:reply, {:ok, data}, state}
    else
      {:reply, {:error, :disconnected}, state, @reconnect_interval}
    end
  end

  def handle_cast(_msg, state) do
    {:noreply, state}
  end

  def handle_info(:timeout, %{node: node, socket: nil}) do
    connect(node)
    |> Tuple.delete_at(0)
    |> Tuple.insert_at(0, :noreply)
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  # private API
  defp connect(%{port: port, host: host}=node) do
    opts = [:binary, packet: :line, active: false, buffer: 1024]
    case :gen_tcp.connect(host, port, opts) do
      {:ok, socket} ->
        Logger.info "Connect to #{host}: #{port} successfully."
        {:ok ,%State{socket: socket, node: node}}
      {:error, err} ->
        {:ok, %State{socket: nil, node: node}, @reconnect_interval}
    end
  end

end
