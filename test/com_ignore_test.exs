defmodule CommandIgnoreTest do
  use ExUnit.Case, async: false
  require IEx

  setup do
    {:ok, sock} = :gen_tcp.connect('localhost', 41300, [:binary, active: false])
    {:ok, sock: sock}
  end

  test "should return NOT IGNORED if the client attempts to ignore the only tube in its watch list", %{sock: sock} do
    :gen_tcp.send(sock, "list-tubes-watched\r\n")
    {:ok, data} = :gen_tcp.recv(sock, 0)

    expected_result = "OK 14\r\n---\n- default\r\n"
    assert expected_result == data

    :gen_tcp.send(sock, "ignore default\r\n")
    {:ok, data} = :gen_tcp.recv(sock, 0)

    expected_result = "NOT_IGNORED\r\n"
    assert expected_result == data
  end

  test "should delete tube from watched list", %{sock: sock} do
    :gen_tcp.send(sock, "watch first\r\n")
    :gen_tcp.send(sock, "watch second\r\n")
    :gen_tcp.send(sock, "watch third\r\n")
    :gen_tcp.recv(sock, 0)

    :gen_tcp.send(sock, "ignore default\r\n")
    assert {:ok, "WATCHING 3\r\n"} == :gen_tcp.recv(sock, 0)

    :gen_tcp.send(sock, "ignore second\r\n")
    assert {:ok, "WATCHING 2\r\n"} == :gen_tcp.recv(sock, 0)

    :gen_tcp.send(sock, "ignore second\r\n")
    assert {:ok, "WATCHING 2\r\n"} == :gen_tcp.recv(sock, 0)

    :gen_tcp.send(sock, "ignore first\r\n")
    assert {:ok, "WATCHING 1\r\n"} == :gen_tcp.recv(sock, 0)

    :gen_tcp.send(sock, "ignore third\r\n")
    assert {:ok, "NOT_IGNORED\r\n"} == :gen_tcp.recv(sock, 0)

    :gen_tcp.send(sock, "list-tubes-watched\r\n")
    {:ok, data} = :gen_tcp.recv(sock, 0)

    expected_result = "OK 12\r\n---\n- third\r\n"
    assert expected_result == data
  end

end
