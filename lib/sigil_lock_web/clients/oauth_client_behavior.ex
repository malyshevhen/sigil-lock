defmodule SigilLockWeb.Clients.OauthClient do
  @callback fetch_jwks() :: {:ok, list()} | {:error, atom()}
end
