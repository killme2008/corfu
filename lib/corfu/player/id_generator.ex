defmodule Corfu.Player.IdGenerator do
  use GenServer
  use Bitwise, only_operators: true

  @name :id_gen

  # Client API
  def start_link(%{host: host, port: _port}) do
    GenServer.start_link(__MODULE__, host, name: @name)
  end

  def next() do
    GenServer.call(@name, :next)
  end

  def reset() do
    GenServer.cast(@name, :reset)
  end

  # Server callbacks
  def init(host) do
    {:ok, %{host: host, val: get_init_val(host)}}
  end

  def handle_call(:next, _from, state) do
    new_val = state.val + 1
    {:reply, new_val, %{state | :val => new_val}}
  end

  def handle_cast(:reset, state) do
    {:noreply, %{state | :val => get_init_val(state.host)}}
  end


  #impl
  defp get_init_val(host) do
    {:ok, t} = :inet.parse_address(host)
    {_, ip} = t
    |> Tuple.to_list()
    |> Enum.reduce({0, 0}, fn(n, {i, ret}) ->
      {i+1, ret + (n <<<  (24 - (8 * i)))}
    end)
    ts = :os.system_time(:milli_seconds)
    Bitwise.bor(ts <<< 32, ip)
  end

end
