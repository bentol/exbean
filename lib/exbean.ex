defmodule Exbean do
  use Application
  import Supervisor.Spec, warn: false

  def start(_, _) do
    children = [
      {Task.Supervisor, name: Exbean.TaskSupervisor},
      {Task, fn -> Exbean.TcpServer.accept(Application.fetch_env!(:exbean, :port)) end},
      {Registry, [keys: :unique, name: :session_profile_registry]}
    ]

    opts = [strategy: :one_for_all, name: Exbean.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
