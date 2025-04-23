defmodule SigilLockWeb.Clients.KeycloakClient do
  @behaviour SigilLockWeb.Clients.OauthClient

  require Logger

  # Get the JWKS URI from the application configuration
  # Use Application.compile_env/3 instead of Application.get_env/2
  @jwks_uri Application.compile_env(:sigil_lock, :jwks_uri)

  @impl SigilLockWeb.Clients.OauthClient
  def fetch_jwks() do
    Logger.info("Fetching JWKS from #{@jwks_uri}")

    case Req.get(@jwks_uri) do
      {:ok, %{status: 200, body: %{"keys" => jwks_list}}} when is_list(jwks_list) ->
        Logger.info("JWKS fetched successfully")

        {:ok, jwks_list}

      {:ok, %{status: status, body: body}} ->
        Logger.error("Failed to fetch JWKS. Status: #{status}, Body: #{inspect(body)}")

        {:error, :unauthenticated}

      {:error, reason} ->
        Logger.error("Failed to fetch JWKS: #{inspect(reason)}")

        {:error, :unauthenticated}
    end
  end
end
