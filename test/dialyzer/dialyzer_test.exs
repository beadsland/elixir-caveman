defmodule CavemanTest.DialyzerTest do
  use ExUnit.Case

  ###
  # Dialyzer errors
  ###

  require Logger

  def seed_memo_filename do
    seed = ExUnit.configuration() |> Keyword.get(:seed)
    System.tmp_dir! |> Path.join("#{__MODULE__}.seed_memo_#{seed}")
  end

  def seed_memo_clean do
    System.tmp_dir!
      |> Path.join("#{__MODULE__}.seed_memo_*")
      |> Path.wildcard()
      |> Enum.each(fn x -> File.rm(x) end)
  end

  def get_seed_memo do
    memo = seed_memo_filename()
    if File.exists?(memo) do
      {:ok, File.read!(memo) |> :erlang.binary_to_term()}
    else
      :undefined
    end
  end

  def set_seed_memo(term) do
    seed_memo_clean()
    bin = :erlang.term_to_binary(term)
    seed_memo_filename() |> File.write!(bin)
  end

  def get_dialyzer_results do
    case get_seed_memo() do
      {:ok, {stdout, status}} -> {stdout, status}
      :undefined ->
        IO.puts("\nRunning dialyzer...")
        task = ["dialyzer", "--quiet"]
        {stdout, status} = System.cmd "mix", task, stderr_to_stdout: true
        set_seed_memo({stdout, status})

        color = case status do
          0 -> IO.ANSI.green
          1 -> IO.ANSI.red
          2 -> IO.ANSI.yellow
        end
        stderr = [color, stdout, IO.ANSI.reset]
        IO.puts(:standard_error, stderr)

        {stdout, status}
    end
  end

  @tag :dialyzer
  test "any dialyzer errors" do
    {_stdout, status} = get_dialyzer_results()
    status = case status do
      0 -> :ok
      1 -> :problems_encountered
      2 -> :warnings_emitted
    end

    assert status == :ok
  end

  @tag :dialyzer
  test "suppress call_to_missing on ?Hello/0" do
    testfile = "caveman_dialyzer_warning.erl"
    {stdout, _status} = get_dialyzer_results()
    stdout = stdout
      |> String.split("\n")
      |> Enum.filter(fn x -> x =~ testfile end)
      |> Enum.join("\n")
    refute stdout =~ ~r(#{testfile}:[0-9]+:call_to_missing)
  end

end
