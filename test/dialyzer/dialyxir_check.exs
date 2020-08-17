defmodule CavemanTest.DialyxirCheck do

  def plt_unbuilt do
    built = Dialyxir.Project.plt_file()
      |> String.replace(~r/_build.test.dialyxir/,
                        Path.join(["_build", "dev","dialyxir"]))
      |> String.replace(~r/-test\.plt$/, "-dev.plt")
      |> File.exists?()

    if not built, do: skipmsg()
    not built
  end

  def skipmsg() do
    msg = [IO.ANSI.yellow,
           "PLT unbuilt: skipping dialyzer tests. Run `mix dialyzer --plt` to build.",
           IO.ANSI.reset]
    IO.puts(:standard_error, msg)
  end

end
