defmodule Exbean.CommandHandler.ListTubeUsed do

  def handle(socket) do
    case Exbean.SessionProfile.get_used_tube(socket) do
      {:ok, tube} -> {:ok, "USING #{tube}"}
      {:error} -> {:internal_error}
    end
  end
end
