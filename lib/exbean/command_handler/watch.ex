defmodule Exbean.CommandHandler.Watch do
  require IEx

  def handle(tube, socket) do
    {:ok, watched_tubes} = Exbean.SessionProfile.watch_tube(socket, tube)
    {:ok, "WATCHING #{length(watched_tubes)}"}
  end

end
