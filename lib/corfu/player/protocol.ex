defmodule Corfu.Player.Protocol do

  def encode_v(nil) do
    "nil"
  end

  def encode_v(v) do
    v
  end

  def decode_v("nil") do
    nil
  end
  def decode_v(v) do
    v
  end
end
