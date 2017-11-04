defmodule TestHelper do
  def get_job_id(data) do
    regex = ~r/INSERTED (?<job_id>\d+)\r\n/
    Regex.named_captures(regex, data) |> Map.get("job_id")
  end
end

ExUnit.configure(exclude: [pending: true])
ExUnit.start()
