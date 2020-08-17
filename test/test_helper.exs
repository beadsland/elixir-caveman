["dialyzer", "dialyxir_check.exs"] |> Path.join |> Code.require_file(__DIR__)

if CavemanTest.DialyxirCheck.plt_unbuilt() do
  ExUnit.configure(exclude: :dialyzer)
end

ExUnit.start()
