defmodule CommandWatchTest do
  use ExUnit.Case

  setup do
    {:ok, sock} = :gen_tcp.connect('localhost', 41300, [:binary, active: false])
    {:ok, sock: sock}
  end

  test "use ${tube}, should return 'USING ${tube}", %{sock: sock} do
    :gen_tcp.send(sock, "use newtube\r\n")
    {:ok, data} = :gen_tcp.recv(sock, 0)
    assert "USING newtube\r\n" == data
  end

  test "use ${tube}, cannot start with hypen", %{sock: sock} do
    :gen_tcp.send(sock, "use -newtube\r\n")
    {:ok, data} = :gen_tcp.recv(sock, 0)
    assert "BAD_FORMAT\r\n" == data
  end

  test "use ${tube}, minimal 1 character", %{sock: sock} do
    :gen_tcp.send(sock, "use \r\n")
    {:ok, data} = :gen_tcp.recv(sock, 0)
    assert "BAD_FORMAT\r\n" == data
  end

  test "use ${tube}, maximum 200 bytes", %{sock: sock} do
    tube = String.duplicate("A", 201)
    :gen_tcp.send(sock, "use #{tube}\r\n")
    {:ok, data} = :gen_tcp.recv(sock, 0)
    assert "BAD_FORMAT\r\n" == data

    tube2 = String.duplicate("A", 200)
    :gen_tcp.send(sock, "use #{tube2}\r\n")
    {:ok, data} = :gen_tcp.recv(sock, 0)
    assert "USING #{tube2}\r\n" == data
  end

  test "use ${tube}, cannot contain forbidden symbol", %{sock: sock} do
    :gen_tcp.send(sock, "use mytube*\r\n")
    {:ok, data} = :gen_tcp.recv(sock, 0)
    assert "BAD_FORMAT\r\n" == data
  end

  test "use ${tube}, can contain whitelisted symbol", %{sock: sock} do
    tube = "$a9-+/;.$_()"
    :gen_tcp.send(sock, "use #{tube}\r\n")
    {:ok, data} = :gen_tcp.recv(sock, 0)
    assert "USING #{tube}\r\n" == data
  end
end
