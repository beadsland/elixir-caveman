defmodule CavemanTest.Readme.Kernel.MakefileTest do
  use ExUnit.Case

  Code.require_file "common.exs", __DIR__
  alias CavemanTest.Readme.Common

  ###
  # Confirm instructions included for Makefile drop-in
  ###

  test "parse README for Makefile drop-in" do
    Common.get_makefile_kernel_dropin()
  end

end
