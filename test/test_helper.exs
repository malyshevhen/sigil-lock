if Code.ensure_loaded?(Dotenvy) do
  Dotenvy.source(".env")
end

ExUnit.start()
