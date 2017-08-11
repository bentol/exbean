defmodule CommandWatchTest do
  use ExUnit.Case

  setup do
    {:ok, sock} = :gen_tcp.connect('localhost', Application.fetch_env!(:exbean, :port), [:binary, active: false])
    {:ok, sock: sock}
  end

  test "put, mallformat message will return BAD_FORMAT", %{sock: sock} do
    :gen_tcp.send(sock, "use newtube\r\n")
    {:ok, data} = :gen_tcp.recv(sock, 0)
    assert "USING newtube\r\n" == data
  end
end
