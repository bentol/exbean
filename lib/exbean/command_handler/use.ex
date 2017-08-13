defmodule Exbean.CommandHandler.Use do

  def handle("-" <> tube, _socket) do
    {:bad_format}
  end

  def handle(tube, socket) do
    case Exbean.SessionProfile.use_tube(socket, tube) do
      {:ok, ^tube} -> {:ok, "USING #{tube}"}
      {:bad_format} -> {:bad_format}
      _ -> {:error}
    end
  end
end
