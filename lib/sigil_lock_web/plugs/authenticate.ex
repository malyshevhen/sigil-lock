defmodule SigilLockWeb.Plugs.Authenticate do
  @moduledoc """
  Authenticate Plug

  This plug authenticates the user by verifying the JWT token.
  Supports Bearer authentication scheme.

  ## Example

      plug :call, SigilLockWeb.Plugs.Authenticate

  ## Configuration

  The plug requires a KeycloakClient module to be configured in the application environment.
  This module should implement the `fetch_jwks/0` function that returns a list of JWK maps.

  ## Usage

  To use this plug, add it to the pipeline in your router:

      pipeline :authenticated_api do
        plug :call, SigilLockWeb.Plugs.Authenticate
        # Rest of the pipeline
      end
  """

  import Plug.Conn

  require Logger

  @keycloak_client Application.compile_env(:sigil_lock, :keycloak_client)

  @bearer_scheme "Bearer"

  def init(opts), do: opts

  def call(conn, _opts) do
    Logger.debug("Authenticate Plug: Checking for Authorization header")
    # Extract the token from the "Authorization: Bearer <token>" header
    # Ensure there's an auth header
    with [auth_header] <- get_req_header(conn, "authorization"),
         # Ensure it starts with Bearer
         {:ok, token} <- split_auth_header(auth_header),
         # Verify the token
         {:ok, claims} <- verify_jwt(token) do
      # If verification is successful, assign the claims to the connection
      conn |> assign(:user_claims, claims)
    else
      # Match any value returned by the failing step
      _ ->
        conn
        |> send_resp(401, "Unauthorized")
        |> halt()
    end
  end

  @spec split_auth_header(String.t()) :: {:ok, String.t()} | {:error, :invalid_format}
  defp split_auth_header(header) when is_binary(header) do
    with [@bearer_scheme, token] <- String.split(header, " ") do
      {:ok, token}
    else
      _ -> {:error, :invalid_format}
    end
  end

  # Function to fetch the JWK set and verify the JWT
  @spec verify_jwt(String.t()) :: {:ok, map()} | {:error, :unauthenticated}
  defp verify_jwt(token) when is_binary(token) do
    with {:ok, jwks_list} <- @keycloak_client.fetch_jwks() do
      Logger.info("Authenticate Plug: JWK fetched successfully")

      # Get the JWK with the given algorithm
      jwk = get_jwk(jwks_list, "RS256")

      # Create a Joken.Signer from the JWK map
      signer = Joken.Signer.create("RS256", jwk)

      # Verify the token using the created signer
      with {:ok, claims} <- Joken.verify(token, signer) do
        Logger.info("Authenticate Plug: Joken verification successful")
        {:ok, claims}
      else
        {:error, reason} ->
          Logger.warning("Authenticate Plug: Joken verification failed: #{inspect(reason)}")
          {:error, :unauthenticated}
      end
    else
      {:error, reason} ->
        Logger.error("Authenticate Plug: Failed to fetch JWK: #{inspect(reason)}")
        {:error, :unauthenticated}
    end
  end

  @spec get_jwk(list(), binary()) :: map() | nil
  defp get_jwk(keys, alg) when is_list(keys) and is_binary(alg) do
    Enum.find(keys, fn key -> key["alg"] == alg end)
  end
end
