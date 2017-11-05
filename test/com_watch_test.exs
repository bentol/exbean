defmodule CommandWatchTest do
  use ExUnit.Case, async: false
  require IEx

  setup do
    {:ok, sock} = :gen_tcp.connect('localhost', 41300, [:binary, active: false])
    {:ok, sock: sock}
  end

  test "should return default for default tube", %{sock: sock} do
    :gen_tcp.send(sock, "list-tubes-watched\r\n")
    {:ok, data} = :gen_tcp.recv(sock, 0)

    expected_result = "OK 14\r\n---\n- default\r\n"
    assert expected_result == data
  end

  test "should return all watched tube", %{sock: sock} do
    :gen_tcp.send(sock, "watch email\r\n")
    {:ok, data} = :gen_tcp.recv(sock, 0)
    assert "WATCHING 2\r\n" == data 

    :gen_tcp.send(sock, "list-tubes-watched\r\n")
    {:ok, data} = :gen_tcp.recv(sock, 0)

    expected_result = "OK 22\r\n---\n- default\n- email\r\n"
    assert expected_result == data
  end

  test "should return same value if called multiple times", %{sock: sock} do
    :gen_tcp.send(sock, "watch email\r\n")
    {:ok, data} = :gen_tcp.recv(sock, 0)
    assert "WATCHING 2\r\n" == data 

    :gen_tcp.send(sock, "watch email\r\n")
    {:ok, data} = :gen_tcp.recv(sock, 0)
    assert "WATCHING 2\r\n" == data 

    :gen_tcp.send(sock, "watch email\r\n")
    {:ok, data} = :gen_tcp.recv(sock, 0)
    assert "WATCHING 2\r\n" == data 
  end

end
