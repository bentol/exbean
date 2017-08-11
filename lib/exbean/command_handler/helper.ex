defmodule Exbean.CommandHandler.Helper do

  def validate_tube_name(tube) do
    Regex.match?(~r/^[-a-zA-Z0-9$+\/;._()]+$/, tube)
  end

end
