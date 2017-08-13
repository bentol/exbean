defmodule Exbean.SessionProfile do
  use GenServer
  alias Exbean.CommandHandler.Helper

  # Client api
  def start_link(socket) do
    name = via_tuple(socket)
    GenServer.start_link(__MODULE__, [socket], name: name)
  end

  defp via_tuple(socket) do
    {:via, Registry, {:session_profile_registry, socket}}
  end

  def use_tube(socket, tube) do
    GenServer.call(via_tuple(socket), {:use_tube, tube})
  end

  def get_used_tube(socket) do
    GenServer.call(via_tuple(socket), {:get_used_tube})
  end

  # Server implementation
  def init(socket) do
    {:ok, %{socket: socket, use: "default"}}
  end

  def handle_call({:use_tube, tube}, _from, state) do
    cond do
      String.length(tube) < 1 ->
        {:reply, {:bad_format}, state}
      byte_size(tube) > 200 ->
        {:reply, {:bad_format}, state}
      Helper.validate_tube_name(tube) == false ->
        {:reply, {:bad_format}, state}
      true ->
        {:reply, {:ok, tube}, %{state | use: tube}}
    end
  end

  def handle_call({:get_used_tube}, _from, %{use: tube} = state) do
    {:reply, {:ok, tube}, state}
  end
end
