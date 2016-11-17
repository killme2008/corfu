defmodule Corfu do
  require Logger

  def main(args) do
    if Enum.count(args) != 2 do
      Logger.info "Useage: corfu node node-list"
      exit(:badarg)
    end

    node = args |> List.first() |> parse_node
    node_list = args |> List.last() |> parse_nodes

    Corfu.Rpc.Supervisor.start_link()
    rpc_nodes= Corfu.Rpc.Supervisor.connect(node_list)
    Corfu.Player.Supervisor.start_link(node, rpc_nodes)
  end

  # Impl
  defp parse_nodes(s) do
    s
    |> String.split(~r{,}, trim: true)
    |> Enum.map(&parse_node/1)
  end

  defp parse_node(s) do
    [host, port] = s |> String.split(~r{:})
    %{host: String.to_charlist(host), port: String.to_integer(port)}
  end
end
