defmodule Exbean.CommandHandler.Put do
  require IEx

  def handle(command, socket) do
    {:ok, tube } = Exbean.SessionProfile.get_used_tube(socket)
    {:ok, job_id} = Exbean.Tube.put_job(tube, command)
    {:ok, "INSERTED #{job_id}"}
  end

  def build_command(props, buffer) do
    regex = ~r/(?<pri>\d+) (?<delay>\d+) (?<ttr>\d+) (?<bytes>\d+)/
    captures = Regex.named_captures(regex, props[:attrs])
    case captures do
      nil -> {{:bad_format, raw: "put #{props[:attrs]}"}, buffer}
      attrs -> get_payload_from_buffer(props, attrs, buffer)
    end
  end

  defp get_payload_from_buffer(props, attrs, buffer) do
    attrs = attrs |> Enum.map(fn {k, v} -> {k, String.to_integer(v)} end) |> Enum.into(%{})
    payload_bytes_count = attrs["bytes"] + 2
    <<payload::bytes-size(payload_bytes_count)>> <> rest_buffer = buffer

    cond do
      byte_size(buffer) < payload_bytes_count ->
        {nil, "put " <> props[:attrs] <> buffer}
      true ->
        {
          {:put, payload: payload, attrs: attrs},
          rest_buffer
        }
    end
  end
end
