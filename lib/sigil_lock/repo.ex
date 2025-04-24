defmodule SigilLock.Repo do
  use Ecto.Repo,
    otp_app: :sigil_lock,
    adapter: Ecto.Adapters.Postgres
end
