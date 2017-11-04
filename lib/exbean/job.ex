defmodule Exbean.Job do
  require IEx

  defstruct id: nil, bytes: nil, ttr: nil, pri: nil, delay: nil, payload: ""

  def new(id, {:put, props}) do
    %Exbean.Job{
      id: id,
      payload: props[:payload] |> String.trim_trailing("\r\n"),
      bytes: props[:attrs]["bytes"],
      delay: props[:attrs]["delay"],
      pri: props[:attrs]["pri"],
      ttr: max(props[:attrs]["ttr"], 1)
    }
  end
end
