defmodule Exbean.CommandHandler.ListTubesWatched do 
  require IEx

  def handle(sock) do
    tubes = Exbean.SessionProfile.get_watched_tube(sock)
    
    {:ok, build_result(tubes)}
  end

  def build_result(tubes) do
    data = "---\n" <> (tubes
      |> Enum.map(fn tube ->
        "- #{tube}"
      end)
      |> Enum.join("\n"))


    size = byte_size(data) + 1
    result = "OK #{size}\r\n#{data}"
    result
  end
end
