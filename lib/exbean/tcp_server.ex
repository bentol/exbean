defmodule Exbean.TcpServer do
  require Logger

  def accept(port) do
    {:ok, socket} = :gen_tcp.listen(
      port,
      [:binary, active: false, reuseaddr: true]
    )
    Logger.info "Accepting connections on port #{port}"
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(Exbean.TaskSupervisor, fn ->
      serve(client)
    end)

    :ok = :gen_tcp.controlling_process(client, pid)
    loop_acceptor(socket)
  end

  defp serve(socket) do
    socket
    |> read_line()
    |> log_line(socket)
    |> process()
    |> log_output(socket)
    |> write_output(socket)

    serve(socket)
  end

  defp read_line(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} -> String.split(data, [" ", "\r"])
      {:error, :closed} -> Process.exit(self(), :normal)
    end
  end

  defp log_line(line, socket) do
    {:ok, {client_ip, _}} = :inet.peername(socket)
    Logger.debug "New message from #{client_ip |> Tuple.to_list |> Enum.join(".")}: #{Enum.join(line, " ")}"
    {:ok, line}
  end

  defp log_output(line, socket) do
    {:ok, {client_ip, _}} = :inet.peername(socket)
    Logger.warn "Reply to #{client_ip |> Tuple.to_list |> Enum.join(".")}: #{line}"
    line
  end

  defp write_output(output, socket) do
    :gen_tcp.send(socket, output)
  end

  defp process({:ok, ["use", tube, "\n"]}) do
    Exbean.CommandHandler.Use.handle(tube)
  end

  defp process(d) do
    IO.inspect d
    "UNKNOWN_COMMAND\r\n"
  end

end
