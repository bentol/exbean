defmodule Exbean.Tube do
  use GenServer
  alias Exbean.CommandHandler.Helper
  alias Exbean.Job
  alias Exbean.JobIndex

  require IEx

  # Client api
  def start_link(name) do
    tuple_name = via_tuple(name)
    GenServer.start_link(__MODULE__, name, name: tuple_name)
  end

  def start(name) do
    start_link(name)
  end

  defp via_tuple(name) do
    {:via, Registry, {:tube_registry, name}}
  end

  def get_state(tube_name) do
    GenServer.call(via_tuple(tube_name), {:state})
  end

  def put_job(tube_name, job) do
    GenServer.call(via_tuple(tube_name), {:put, job})
  end

  def delete_job(tube_name, job_id) do
    GenServer.call(via_tuple(tube_name), {:delete, job_id})
  end

  def peek_job(nil, job_id) do
    nil
  end

  def peek_job(tube_name, job_id) do
    GenServer.call(via_tuple(tube_name), {:peek, job_id})
  end

  # Server implementation
  def init(name) do
    {:ok, %{name: name,
            jobs: %{},
            ready: [],
            reserved: [],
            delayed: [],
            buried: []}}
  end

  def handle_call({:put, raw_job}, _from, %{jobs: jobs} = state) do
    id = JobIndex.request_id()
    job = Job.new(id, raw_job)
    jobs = Map.put(jobs, id, job)

    JobIndex.register_id(id, Map.get(state, :name))
    {:reply, {:ok, id}, %{state | jobs: jobs}}
  end

  def handle_call({:delete, job_id}, _from, %{jobs: jobs} = state) do
    result = if Map.has_key?(jobs, job_id), do: :ok, else: nil
    job = Map.delete(jobs, job_id)
    {:reply, result, state}
  end

  def handle_call({:peek, job_id}, _from, %{jobs: jobs} = state) do
    job = Map.get(jobs, job_id)
    {:reply, job, state}
  end

  def handle_call({:state}, _from, state) do
    {:reply, state, state}
  end
end
