defmodule Exbean.TcpServer do
  require Logger
  require IEx
  use Rop

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
    serve(socket, "")
  end

  defp serve(socket, buffer) do
    buffer = socket
    |> save_to_buffer(buffer)

    {buffer, commands} = extract_commands(buffer)

    commands
    |> Enum.reverse
    |> Enum.each(fn command ->
      command
      |> log_command(socket)
      |> process()
      |> log_output(socket)
      |> write_output(socket)
    end)

    serve(socket, buffer)
  end

  defp extract_commands(buffer, commands \\ []) do
    case String.contains? buffer, "\r\n" do
      true ->
        raw_command = String.split(buffer, "\r\n", parts: 2, trim: true)
        |> Enum.at(0)

        command = raw_command
        |> normalize_command

        if command == {:error} do
          Process.exit(self(), :error)
        end

        buffer = String.slice(buffer, String.length(raw_command) + 1, 100000)

        extract_commands(buffer, [command | commands])
      false -> {buffer, commands}
    end
  end

  defp save_to_buffer(socket, buffer) do
    data = case :gen_tcp.recv(socket, 0) do
      {:ok, data} -> data
      {:error, :closed} -> Process.exit(self(), :normal)
    end
    buffer <> data
  end

  defp log_command(command, socket) do
    {:ok, {client_ip, _}} = :inet.peername(socket)
    Logger.debug "New message from #{client_ip |> Tuple.to_list |> Enum.join(".")}: #{inspect command}"
    {:ok, command}
  end

  defp log_output(output, socket) do
    {:ok, {client_ip, _}} = :inet.peername(socket)
    Logger.warn "Reply to #{client_ip |> Tuple.to_list |> Enum.join(".")}: #{output}"
    output
  end

  defp write_output(output, socket) do
    :gen_tcp.send(socket, output)
  end

  defp process({:ok, {:use, tube}}) do
    Exbean.CommandHandler.Use.handle(tube)
  end

  defp process(_) do
    "UNKNOWN_COMMAND\r\n"
  end

  defp normalize_command(command) do

    command =
      case {String.at(command, -2), String.at(command, -1)} do
        {"\r", "\n"} -> command |> String.split_at(-1) |> elem(0)
        _ -> command
      end

    case command do
      "use " <> tube -> {:use, tube}
      _ -> {:error}
    end
  end

end
