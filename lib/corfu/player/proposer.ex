defmodule Corfu.Player.Proposer do
  use GenServer
  alias Corfu.Player.Protocol
  alias Corfu.Player.IdGenerator, as: Id
  alias Corfu.Rpc.Supervisor, as: Rpc
  alias Corfu.Player.Bookkeeper

  defmodule State do
	  defstruct maxab: 0,v: nil, qrm: 0, rpc_nodes: []
  end


  # Client API
  def start_link(node, rpc_nodes) do
    GenServer.start_link(__MODULE__, {node, rpc_nodes}, name: :proposer)
  end

  def proposal() do
    GenServer.call(:proposer, :proposal)
  end

  # Server callbacks
  def init({%{host: host, port: port}, rpc_nodes}) do
    qrm = round((map_size(rpc_nodes) + 1)/2)
    {:ok, %State{v: "#{host}:#{port}", qrm: qrm, rpc_nodes: rpc_nodes} }
  end

  def handle_call(:proposal, _from, state) do
    b = Id.next()
    {ok, ab, av} = prepare(state, b)

    {v, new_state} =
    if ab > state.maxab and av != nil do
      {av, %{state | :maxab => ab, :v => av}}
    else
      {state.v, state}
    end

    if ok >= state.qrm do
      a_ok = accept(state, b, v)
      if a_ok >= state.qrm do
        {:reply, {:ok, b, v}, new_state}
      else
        {:reply, :accept_fail, new_state}
      end
    else
      {:reply, :prepare_fail, new_state}
    end
  end

  defp prepare(state, b) do
    Rpc.rpc(state.rpc_nodes, "prepare #{b}\r\n")
    |> Enum.reduce({0, nil, state.v}, fn(res, {ok, maxab, av}) ->
      case res do
        {:ok, line} ->
          line = String.trim(line)
          if line == "reject" do
            {ok, maxab, av}
          else
            [cmd, ab, new_av] = String.split(line, ~r{\s})
            ab = String.to_integer(ab)
            if ab > maxab do
              {ok+1, ab, Protocol.decode_v(new_av)}
            else
              {ok+1, maxab, av}
            end
          end
        {:error, _err} ->
          {ok, maxab, av}
      end
    end)
  end

  defp accept(state, b, v) do
    Rpc.rpc(state.rpc_nodes, "accept #{b} #{Protocol.encode_v(v)}\r\n")
    |> Enum.reduce(0, fn(res, ok) ->
      case res do
        {:ok, line} ->
          cmd = String.trim(line)
          case cmd do
            "ok" ->
              ok + 1
            "reject" ->
              ok
          end
        {:error, _err} ->
          ok
      end
    end)
  end

end
