defmodule Exbean.CommandHandler.Ignore do
  require IEx

  def handle(tube, socket) do
    case Exbean.SessionProfile.ignore_tube(socket, tube) do
      {:ok, watched_tubes} ->
        {:ok, "WATCHING #{length(watched_tubes)}"}
      {:error, :not_ignored} ->
        {:ok, "NOT_IGNORED"}
    end
  end

end
