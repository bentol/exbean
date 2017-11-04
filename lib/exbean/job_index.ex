defmodule Exbean.JobIndex do
  use GenServer

  # Client api
  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def request_id do
    GenServer.call(__MODULE__, :request_id)
  end

  def register_id(id, tube_name) do
    GenServer.cast(__MODULE__, {:register_id, id, tube_name})
  end

  def delete_job(id) do
    GenServer.call(__MODULE__, {:delete_id, id})
  end

  def get_tube_name_from_id(job_id) do
    GenServer.call(__MODULE__, {:get_tube_name_from_id, job_id})
  end

  # Server implementation
  def init(:ok) do
    {:ok, %{counter: 1, jobs: %{}}}
  end

  def handle_call({:get_tube_name_from_id, job_id}, _from, %{jobs: jobs} = state) do
    {:reply, Map.get(jobs, job_id ), state}
  end

  def handle_call(:request_id, _from, %{counter: c} = state) do
    {:reply, c, %{state | counter: c + 1 }}
  end

  def handle_call({:delete_id, job_id}, _from, %{jobs: jobs} = state) do
    result = if Map.has_key?(jobs, job_id), do: :ok, else: nil
    new_jobs = Map.delete(jobs, job_id)
    {:reply, result, %{state | jobs: new_jobs }}
  end

  def handle_cast({:register_id, job_id, tube_name}, %{jobs: jobs} = state) do
    new_jobs = Map.put(jobs, job_id, tube_name)
    {:noreply, %{state | jobs: new_jobs }}
  end
end
