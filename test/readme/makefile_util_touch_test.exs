defmodule CavemanTest.Readme.Makefile.Util.TouchTest do
  use ExUnit.Case

  ###
  # Test platform-agnostic touch used by Makefile drop-in
  ###

  def get_touch_test_env do
    touch = [File.cwd!(), "util", "touch.escript"] |> Path.join()
    tempdir = System.tmp_dir!()
    seed = ExUnit.configuration() |> Keyword.get(:seed)
    testdir = "#{__MODULE__}_touchtest_seed_#{seed}"

    [tempdir, testdir] |> Path.join() |> File.mkdir!

    %{touch: touch, tempdir: tempdir, testdir: testdir}
  end

  def clean_touch_test_env(env, files) do
    files |> Enum.each(fn x->
      [env[:tempdir], env[:testdir], x] |> Path.join() |> File.rm!()
    end)
    [env[:tempdir], env[:testdir]] |> Path.join() |> File.rmdir!()
  end

  def do_touch_test(env, file) do
    env[:tempdir] |> File.cd!(fn ->
      System.cmd env[:touch], [Path.join(env[:testdir], file)]
    end)
    [env[:tempdir], env[:testdir], file]
      |> Path.join()
      |> File.stat([time: :posix])
  end

  test "create file with touch.escript" do
    env = get_touch_test_env()
    result = do_touch_test env, "apple"
    clean_touch_test_env env, ["apple"]
    {:ok, _info} = result
  end

  test "redate file with touch.escript" do
    env = get_touch_test_env()
    result1 = do_touch_test env, "apple"
    :timer.sleep(1000)
    result2 = do_touch_test env, "apple"
    clean_touch_test_env env, ["apple"]

    {:ok, info1} = result1
    {:ok, info2} = result2

    assert info1.mtime != info2.mtime
  end

  test "redate multiple files with touch.escript" do
    env = get_touch_test_env()
    result1a = do_touch_test env, "apple"
    result1b = do_touch_test env, "berry"
    :timer.sleep(1000)
    result2a = do_touch_test env, "apple"
    result2b = do_touch_test env, "berry"
    clean_touch_test_env env, ["apple", "berry"]

    {:ok, info1a} = result1a
    {:ok, info2a} = result2a
    {:ok, info1b} = result1b
    {:ok, info2b} = result2b

    assert info1a.mtime != info2a.mtime
    assert info1b.mtime != info2b.mtime
  end

end
