defmodule Exbean.CommandHandler.Delete do 
  @not_found "NOT_FOUND"
  @deleted "DELETED"

  def handle({:delete, job_id}, socket) do
    job_id = job_id |> String.to_integer
    tube_name = Exbean.JobIndex.get_tube_name_from_id(job_id)

    delete_job_operation = fn ->
      {
        Exbean.JobIndex.delete_job(job_id),
        Exbean.Tube.delete_job(tube_name, job_id)
      }
    end

    case tube_name && delete_job_operation.() do
      nil -> {:ok, @not_found}
      {:ok, :ok} -> {:ok, @deleted}
      _ -> {:ok, @not_found}
    end

  end
end
