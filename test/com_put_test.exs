defmodule CommandPutTest do
  use ExUnit.Case, async: false
  require IEx

  @bad_format "BAD_FORMAT\r\n"

  setup do
    {:ok, sock} = :gen_tcp.connect('localhost', 41300, [:binary, active: false])
    {:ok, sock: sock}
  end

  test "put, mallformat message will return BAD_FORMAT", %{sock: sock} do
    bad_commands = [
      "put pri delay ttr bytes\r\n",
      "put 1 delay ttr bytes\r\n",
      "put pri 1 ttr bytes\r\n",
      "put pri delay 1 bytes\r\n",
      "put pri delay ttr 1\r\n",
      "put -1 -1 -1 -1\r\n",
    ]

    bad_commands
    |> Enum.each(fn command ->
      :gen_tcp.send(sock, command)
      {:ok, data} = :gen_tcp.recv(sock, 0)
      assert @bad_format == data
    end)
  end

  test "put, will return inserted", %{sock: sock} do
    command = "put 0 0 0 10\r\n1234567890\r\n"
    :gen_tcp.send(sock, command)
    {:ok, data} = :gen_tcp.recv(sock, 0)
    regex = ~r/INSERTED (?<job_id>\d+)\r\n/
    assert Regex.match?(regex, data)
    job_id = Regex.named_captures(regex, data) |> Map.get("job_id")

    :gen_tcp.send(sock, "peek #{job_id}\r\n")
    {:ok,data} = :gen_tcp.recv(sock, 0)
    assert "FOUND #{job_id} 10\r\n1234567890\r\n" == data
  end

  test "put, will increase id counter", %{sock: sock} do
    command = "put 0 0 0 5\r\n12345\r\n"
    :gen_tcp.send(sock, command)
    {:ok, data} = :gen_tcp.recv(sock, 0)
    regex = ~r/INSERTED (?<job_id>\d+)\r\n/
    assert Regex.match?(regex, data)
    job_id1 = Regex.named_captures(regex, data) |> Map.get("job_id")

    :gen_tcp.send(sock, "use new_tube\r\n")
    :gen_tcp.recv(sock, 0)
    command = "put 0 0 0 5\r\n12345\r\n"
    :gen_tcp.send(sock, command)
    {:ok, data} = :gen_tcp.recv(sock, 0)
    regex = ~r/INSERTED (?<job_id>\d+)\r\n/
    assert Regex.match?(regex, data)
    job_id2 = Regex.named_captures(regex, data) |> Map.get("job_id")

    assert job_id1 != job_id2
  end

  test "put, should insert to new tube", %{sock: sock} do
    command = "use hole\r\nput 0 0 0 10\r\n1234567890\r\n"
    :gen_tcp.send(sock, command)
    {:ok, data} = :gen_tcp.recv(sock, 0)
    regex = ~r/INSERTED (?<job_id>\d+)\r\n/
    assert Regex.match?(regex, data)
    job_id = Regex.named_captures(regex, data) |> Map.get("job_id")

    :gen_tcp.send(sock, "peek #{job_id}\r\n")
    {:ok,data} = :gen_tcp.recv(sock, 0)
    IO.inspect data
    assert "FOUND #{job_id} 10\r\n1234567890\r\n" == data
  end

end
