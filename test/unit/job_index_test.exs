defmodule JobIndexTest do
  use ExUnit.Case, async: false
  require IEx

  setup do
    {:ok, sock} = :gen_tcp.connect('localhost', 41300, [:binary, active: false])
    {:ok, sock: sock}
  end

  test 'should store map id with tube name properly' do
    Exbean.JobIndex.register_id(3, "hole")
    assert "hole" == Exbean.JobIndex.get_tube_name_from_id(3)
  end
end
