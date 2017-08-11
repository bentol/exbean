defmodule Exbean.CommandHandler.Use do
  @bad_format "BAD_FORMAT\r\n"
  alias Exbean.CommandHandler.Helper

  def handle("-" <> tube) do
    @bad_format
  end

  def handle(tube) do
    cond do
      String.length(tube) < 1 ->
        @bad_format
      byte_size(tube) > 200 ->
        @bad_format
      Helper.validate_tube_name(tube) == false ->
        @bad_format
      true ->
        "USING #{tube}\r\n"
    end
  end

  def handle(_) do
    @bad_format
  end

end
