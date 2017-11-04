defmodule CommandDeleteTest do
  use ExUnit.Case, async: false
  require IEx

  @not_found "NOT_FOUND\r\n"
  @deleted "DELETED\r\n"

  setup do
    {:ok, sock} = :gen_tcp.connect('localhost', 41300, [:binary, active: false])
    {:ok, sock: sock}
  end

  test "should return NOT_FOUND if delete non existant job", %{sock: sock} do
    :gen_tcp.send(sock, "delete 117\r\n")
    {:ok, data} = :gen_tcp.recv(sock, 0)
    assert @not_found == data
  end

  test "should delete ready job", %{sock: sock} do

    command = "put 0 0 0 5\r\nfirst\r\n"
    :gen_tcp.send(sock, command)
    {:ok, data} = :gen_tcp.recv(sock, 0)
    job_id = TestHelper.get_job_id(data)

    # peek before delete, must exist
    :gen_tcp.send(sock, "peek #{job_id}\r\n")
    {:ok, data} = :gen_tcp.recv(sock, 0)
    assert "FOUND #{job_id} 5\r\nfirst\r\n" == data

    # delete here
    :gen_tcp.send(sock, "delete #{job_id}\r\n")
    {:ok, data} = :gen_tcp.recv(sock, 0)
    assert @deleted == data

    # peek after delete, must deleted
    :gen_tcp.send(sock, "peek #{job_id}\r\n")
    {:ok, data} = :gen_tcp.recv(sock, 0)
    assert @not_found == data

  end

  @tag :pending
  test "should delete burried job", %{sock: sock} do
  end

  @tag :pending
  test "should delete delayed job", %{sock: sock} do
  end

  @tag :pending
  test "should delete reserved job", %{sock: sock} do
  end
end
