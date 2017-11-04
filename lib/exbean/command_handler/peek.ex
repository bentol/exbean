defmodule Exbean.CommandHandler.Peek do
  require IEx

  def handle({:peek, job_id}, socket) do
    job_id = job_id |> String.to_integer
    tube_name = Exbean.JobIndex.get_tube_name_from_id(job_id)
    case Exbean.Tube.peek_job(tube_name, job_id) do
      %{id: id, payload: payload, bytes: bytes} ->
        {:ok, "FOUND #{id} #{bytes}\r\n#{payload}"}
      _ -> {:ok, "NOT_FOUND"}
    end
  end
end
