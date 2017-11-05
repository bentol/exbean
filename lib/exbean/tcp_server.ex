defmodule Exbean.TcpServer do
  require Logger
  require IEx
  use Rop

  @internal_error "INTERNAL_ERROR\r\n"
  @bad_format "BAD_FORMAT\r\n"

  def accept(port) do
    Exbean.Tube.start("default")

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
    Exbean.SessionProfile.start_link(socket)
    serve(socket, "")
  end

  defp serve(socket, buffer) do
    buffer = socket
    |> save_to_buffer(buffer)

    {buffer, commands} = extract_commands(buffer)

    output_buffer = commands
    |> Enum.reverse
    |> Enum.map(fn command ->
      IO.inspect "+++"
      IO.inspect command
      IO.inspect "---"
      command
      |> log_command(socket)
      |> process(socket)
      |> log_output(socket)
    end)
    |> Enum.join()

    write_output(output_buffer, socket)

    serve(socket, buffer)
  end

  defp extract_commands(buffer, commands \\ []) do
    case String.contains? buffer, "\r\n" do
      true ->
        raw_command = String.split(buffer, "\r\n", parts: 2, trim: true)
        |> Enum.at(0)

        command = raw_command
        |> normalize_command

        buffer = String.slice(buffer, String.length(raw_command) + 1, 100000)

        {command, buffer} =
          case command do
            {:put, attrs} -> Exbean.CommandHandler.Put.build_command(attrs, buffer)
            _ -> {command, buffer}
          end

        case command do
          nil -> {buffer, commands}
          _ -> extract_commands(buffer, [command | commands])
        end

      false -> {buffer, commands}
    end
  end

  defp save_to_buffer(socket, buffer) do
    data =
      case :gen_tcp.recv(socket, 0) do
        {:ok, data} -> data
        {:error, :closed} -> Process.exit(self(), :normal)
      end
    buffer <> data
  end

  defp log_command({:error, command}, socket) do
    {:ok, {client_ip, _}} = :inet.peername(socket)
    Logger.debug "Invalid message from #{client_ip |> Tuple.to_list |> Enum.join(".")}: #{inspect command}"
    {:error, command}
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

  defp process({:ok, {:use, tube}}, socket) do
    case Exbean.CommandHandler.Use.handle(tube, socket) do
      {:ok, msg} -> msg <> "\r\n"
      {:error, msg} -> msg <> "\r\n"
      {:bad_format} -> @bad_format
      {:error} -> @internal_error
    end
  end

  defp process({:ok, {:watch, tube}}, socket) do
    case Exbean.CommandHandler.Watch.handle(tube, socket) do
      {:ok, msg} -> msg <> "\r\n"
      {:bad_format} -> @bad_format
      {:error} -> @internal_error
    end
  end

  defp process({:ok, {:ignore, tube}}, socket) do
    case Exbean.CommandHandler.Ignore.handle(tube, socket) do
      {:ok, msg} -> msg <> "\r\n"
      {:bad_format} -> @bad_format
      {:error} -> @internal_error
    end
  end

  defp process({:ok, {:"list-tube-used"}}, socket) do
    case Exbean.CommandHandler.ListTubeUsed .handle(socket) do
      {:ok, msg} -> msg <> "\r\n"
      _ -> @bad_format
    end
  end

  defp process({:ok, {:"list-tubes-watched"}}, socket) do
    case Exbean.CommandHandler.ListTubesWatched.handle(socket) do
      {:ok, msg} -> msg <> "\r\n"
      _ -> @bad_format
    end
  end

  defp process({:ok, {:put, props} = command}, socket) do
    case Exbean.CommandHandler.Put.handle(command, socket) do
      {:ok, msg} -> msg <> "\r\n"
      _ -> @bad_format
    end
  end

  defp process({:ok, {:peek, job_id} = command}, socket) do
    case Exbean.CommandHandler.Peek.handle(command, socket) do
      {:ok, msg} -> msg <> "\r\n"
      _ -> @bad_format
    end
  end

  defp process({:ok, {:delete, job_id} = command}, socket) do
    case Exbean.CommandHandler.Delete.handle(command, socket) do
      {:ok, msg} -> msg <> "\r\n"
      _ -> @bad_format
    end
  end

  defp process({:ok, {:bad_format, _}}, _) do
    "BAD_FORMAT\r\n"
  end

  defp process(_, _) do
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
      "watch " <> tube -> {:watch, tube}
      "ignore " <> tube -> {:ignore, tube}
      "list-tube-used" -> {:"list-tube-used"}
      "list-tubes-watched" -> {:"list-tubes-watched"}
      "put " <> attrs -> {:put, attrs: attrs }
      "peek " <> job_id -> {:peek, job_id}
      "delete " <> job_id -> {:delete, job_id}
      _ -> {:error, command}
    end
  end

end
