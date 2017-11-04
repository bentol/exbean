defmodule Exbean do
  use Application
  import Supervisor.Spec, warn: false

  def start(_, _) do
    children = [
      {Exbean.JobIndex, []},
      Supervisor.child_spec({Registry,  [keys: :unique, name: :session_profile_registry]}, id: :session_profile_registry),
      Supervisor.child_spec({Registry,  [keys: :unique, name: :tube_registry]}, id: :tube_registry),
      {Task.Supervisor, name: Exbean.TaskSupervisor},
      {Task, fn -> Exbean.TcpServer.accept(Application.fetch_env!(:exbean, :port)) end}
    ]

    opts = [strategy: :one_for_one, name: Exbean.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
