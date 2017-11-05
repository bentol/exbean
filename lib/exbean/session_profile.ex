defmodule Exbean.SessionProfile do
  use GenServer
  alias Exbean.CommandHandler.Helper
  require IEx

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

  def watch_tube(socket, tube) do
    GenServer.call(via_tuple(socket), {:watch_tube, tube})
  end

  def ignore_tube(socket, tube) do
    GenServer.call(via_tuple(socket), {:ignore_tube, tube})
  end

  def get_watched_tube(socket) do
    GenServer.call(via_tuple(socket), {:get_watched_tube})
  end

  # Server implementation
  def init(socket) do
    {:ok,
      %{
        socket: socket,
        use: "default",
        watched: ["default"]
      }
    }
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
        {:ok, _} = Exbean.Tube.start(tube)
        {:reply, {:ok, tube}, %{state | use: tube}}
    end
  end

  def handle_call({:watch_tube, tube}, _from, %{watched: watched_tubes} = state) do

    cond do
      Helper.validate_tube_name(tube) == false ->
        {:reply, {:bad_format}, state}
      true ->
        {:ok, _} = Exbean.Tube.start(tube)
        watched_tubes = case Enum.member?(watched_tubes, tube) do
          true -> watched_tubes
          false -> watched_tubes ++ [tube]
        end
        {:reply, {:ok, watched_tubes}, %{state | watched: watched_tubes}}
    end
  end

  def handle_call({:ignore_tube, tube}, _from, %{watched: watched_tubes} = state) do
    {reply, watched_tubes} =
      case {Enum.member?(watched_tubes, tube), length(watched_tubes)} do
        {true, 1} -> { {:error, :not_ignored}, watched_tubes}
        _ -> 
          new_watched_tubes = List.delete(watched_tubes, tube)
          { {:ok, new_watched_tubes}, new_watched_tubes}
      end

    {:reply, reply, %{state | watched: watched_tubes}}
  end

  def handle_call({:get_used_tube}, _from, %{use: tube} = state) do
    {:reply, {:ok, tube}, state}
  end

  def handle_call({:get_watched_tube}, _from, %{watched: tubes} = state) do
    {:reply, tubes, state}
  end
end
