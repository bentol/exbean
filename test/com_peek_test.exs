defmodule CommandPeekTest do
  use ExUnit.Case, async: false
  require IEx

  @bad_format "BAD_FORMAT\r\n"
  @not_found "NOT_FOUND\r\n"

  setup do
    {:ok, sock} = :gen_tcp.connect('localhost', 41300, [:binary, active: false])
    {:ok, sock: sock}
  end

  test "should return job the job", %{sock: sock} do
    command = "put 0 0 0 10\r\n1234567890\r\n"
    :gen_tcp.send(sock, command)
    {:ok, data} = :gen_tcp.recv(sock, 0)
    regex = ~r/INSERTED (?<job_id>\d+)\r\n/
    job_id = Regex.named_captures(regex, data) |> Map.get("job_id")

    :gen_tcp.send(sock, "peek #{job_id}\r\n")
    {:ok,data} = :gen_tcp.recv(sock, 0)
    assert "FOUND #{job_id} 10\r\n1234567890\r\n" == data
  end

  test "should handle even after multiple put", %{sock: sock} do
    command = "put 0 0 0 10\r\n1234567890\r\n"
    :gen_tcp.send(sock, command)
    {:ok, data1} = :gen_tcp.recv(sock, 0)
    regex1 = ~r/INSERTED (?<job_id>\d+)\r\n/
    job_id1 = Regex.named_captures(regex1, data1) |> Map.get("job_id")

    command2 = "use number2\r\nput 0 0 0 5\r\nfirst\r\n"
    :gen_tcp.send(sock, command2)
    {:ok, data2} = :gen_tcp.recv(sock, 0)
    regex2 = ~r/INSERTED (?<job_id>\d+)\r\n/
    job_id2 = Regex.named_captures(regex2, data2) |> Map.get("job_id")

    command3 = "put 0 0 0 6\r\nsecond\r\n"
    :gen_tcp.send(sock, command3)
    {:ok, data3} = :gen_tcp.recv(sock, 0)
    regex3 = ~r/INSERTED (?<job_id>\d+)\r\n/
    job_id3 = Regex.named_captures(regex3, data3) |> Map.get("job_id")

    :gen_tcp.send(sock, "peek #{job_id1}\r\n")
    {:ok,data} = :gen_tcp.recv(sock, 0)
    assert "FOUND #{job_id1} 10\r\n1234567890\r\n" == data

    :gen_tcp.send(sock, "peek #{job_id2}\r\n")
    {:ok,data} = :gen_tcp.recv(sock, 0)
    assert "FOUND #{job_id2} 5\r\nfirst\r\n" == data

    :gen_tcp.send(sock, "peek #{job_id3}\r\n")
    {:ok,data} = :gen_tcp.recv(sock, 0)
    assert "FOUND #{job_id3} 6\r\nsecond\r\n" == data
  end

  test "should not return non existant job", %{sock: sock} do
    :gen_tcp.send(sock, "peek 100\r\n")
    {:ok, data} = :gen_tcp.recv(sock, 0)
    assert @not_found == data
  end

  @tag :pending
  test "should not return deleted job" do
  end

end
