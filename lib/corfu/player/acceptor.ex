defmodule Corfu.Player.Acceptor do
  use GenServer
  alias Corfu.Player.Protocol
  alias Corfu.Player.Bookkeeper
  require Logger


  # Client API
  def start_link(node) do
    GenServer.start_link(__MODULE__, node, name: :acceptor)
  end

  # Server callbacks
  def init(%{host: _host, port: port}) do
    options = [:binary, packet: :line, active: false,
               reuseaddr: true, buffer: 1024]
    case :gen_tcp.listen(port, options) do
      {:ok, socket_server} ->
        Logger.info "Acceptor listening on #{port}"
        GenServer.cast(self, :accept)
        {:ok, socket_server}
      {:error, reason} ->
        {:stop, reason}
    end
  end

  def handle_cast(:accept, socket_server) do
    case :gen_tcp.accept(socket_server, 500) do
      {:ok, socket_client} ->
        serve(socket_client)
        GenServer.cast(self, :accept)
        {:noreply, socket_server}
      {:error, :timeout} ->
        GenServer.cast(self, :accept)
        {:noreply, socket_server}
      {:error, reason} ->
        {:stop, reason, socket_server}
    end
  end

  def terminate(reason, socket_server) do
    Logger.info "Acceptor listener terminating because #{inspect reason}"
    :gen_tcp.close(socket_server)
    :ok
  end

  defp serve(socket) do
    spawn(fn ->
      handle(socket)
    end)
  end

  defp handle(socket) do
    {:ok, line} = :gen_tcp.recv(socket, 0)
    vs = line |> String.trim() |> String.split(~r{\s}, trim: true)
    handle_cmd(vs, socket)
    handle(socket)
  end

  defp handle_cmd(["prepare", b], socket) do
    b = String.to_integer(b)
    case Bookkeeper.handle_prepare(b) do
      {:ok, ab, av} ->
        :gen_tcp.send(socket, "ok #{ab} #{Protocol.encode_v(av)}\r\n")
      {:reject, _} ->
        :gen_tcp.send(socket, "reject\r\n")
    end
  end

  defp handle_cmd(["accept", b, v], socket) do
    b = String.to_integer(b)
    v = Protocol.decode_v(v)
    case Bookkeeper.handle_accept(b, v) do
      :ok ->
        :gen_tcp.send(socket, "ok\r\n")
      :reject ->
        :gen_tcp.send(socket, "reject\r\n")
    end
  end

end
