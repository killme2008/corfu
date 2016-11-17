defmodule Corfu.Player.Bookkeeper do
  use GenServer
  @name :bookkkeeper

  defmodule State do
	  defstruct pb: 0, ab: 0, av: nil
  end


  # Client API
  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: @name)
  end

  def handle_prepare(b) do
    GenServer.call(@name, {:prepare, b})
  end

  def handle_accept(b, v) do
    GenServer.call(@name, {:accept, b, v})
  end

  def get_state() do
    GenServer.call(@name, {:get})
  end

  # Server callbacks
  def init(:ok) do
    {:ok, %State{}}
  end

  def handle_call({:get}, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:prepare, b}, _from, state) do
    if b >= state.pb do
      {:reply, {:ok, state.ab, state.av}, %{state | :pb => b}}
    else
      {:reply, {:reject, :less_than_pb}, state}
    end
  end

  def handle_call({:accept, b, v}, _from, state) do
    if b == state.pb do
      {:reply, :ok, %{state | :ab => b, :av => v}}
    else
      {:noreply,:reject, state}
    end
  end

  def handle_call(msg, from, state) do
    super(msg, from, state)
  end

end
