defmodule CavemanTest.Readme.Kernel.MakefileTest do
  use ExUnit.Case

  Code.require_file "common.exs", __DIR__
  alias CavemanTest.Readme.Common

  ###
  # Confirm instructions included for Makefile drop-in
  ###

  test "parse README for Makefile drop-in" do
    {:ok, _str} = Common.get_readme_code "makefile", "default: compile caveman"
  end

end
