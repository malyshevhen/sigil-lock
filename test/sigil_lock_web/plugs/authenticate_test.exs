defmodule SigilLockWeb.Plugs.AuthenticateTest do
  use ExUnit.Case, async: true

  require Logger

  import Plug.Conn
  import Mox

  alias SigilLockWeb.Plugs.Authenticate
  alias JOSE.{JWK, JWS, JWT}
  alias Req

  # Setup test data: generate a key pair and a valid token
  setup do
    # Generate a test RSA key pair
    # Use a case statement to handle the potential error from generate_key
    jwk =
      JWK.generate_key({:rsa, 2048})
      |> JWK.merge(%{"kid" => "test-key-id"})

    jws = JWS.from_map(%{"alg" => "RS256", "typ" => "JWT"})

    # Create test claims
    current_time = :os.system_time(:second)

    jwt = %{
      "sub" => "testuser_123",
      "name" => "Test User",
      "exp" => current_time + 3600,
      "iat" => current_time,
      "iss" => "http://localhost:8080/realms/sigil-lock",
      "aud" => "sigil-lock-app"
    }

    # Convert public key to map format for mocking the JWKS endpoint response
    # Use case to explicitly handle the result of JWK.to_map
    {_kty, pub_jwk_map} = JWK.to_public(jwk) |> JWK.to_map()

    # Sign the token with the private key and compact the result into a string
    {_alg, valid_token} = JWT.sign(jwk, jws, jwt) |> JWS.compact()

    # Create an invalid token (e.g., wrong signature)
    invalid_token = "invalid.token.string"

    # Return test context
    %{
      pub_jwk_map: pub_jwk_map,
      valid_token: valid_token,
      invalid_token: invalid_token,
      expected_claims: jwt
    }
  end

  # Helper function to create a test connection with the Plug.Test adapter
  defp build_conn() do
    # This creates a connection with the Plug.Test adapter
    Plug.Test.conn(:get, "/")
  end

  describe "call/2" do
    test "assigns user_claims and passes conn when token is valid", %{
      pub_jwk_map: pub_jwk_map,
      valid_token: valid_token,
      expected_claims: expected_claims
    } do
      # Arrange: Create a connection with a valid Authorization header
      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{valid_token}")

      KeycloakClientMock
      |> expect(:fetch_jwks, fn -> {:ok, [pub_jwk_map]} end)

      # Act: Call the Authenticate Plug
      # The Plug is expected to return the connection if successful
      returned_conn = Authenticate.call(conn, [])

      # Assert: The connection is not halted and user_claims are assigned
      assert %{halted: true} = Plug.Conn.halt(returned_conn)
      assert returned_conn.assigns[:user_claims] == expected_claims
    end

    test "halts conn and returns 401 when Authorization header is missing" do
      # Arrange: Create a connection with no Authorization header
      conn = build_conn()

      # Act: Call the Authenticate Plug
      returned_conn = Authenticate.call(conn, [])

      # Assert: The connection is halted and a 401 response is sent
      assert %{halted: true} = Plug.Conn.halt(returned_conn)
      assert returned_conn.state == :sent
      assert returned_conn.status == 401
    end

    test "halts conn and returns 401 when Authorization header is malformed" do
      # Arrange: Create a connection with a malformed Authorization header
      conn =
        build_conn()
        |> put_req_header("authorization", "Basic user:pass")

      # Act: Call the Authenticate Plug
      returned_conn = Authenticate.call(conn, [])

      # Assert: The connection is halted and a 401 response is sent
      assert %{halted: true} = Plug.Conn.halt(returned_conn)
      assert returned_conn.state == :sent
      assert returned_conn.status == 401
    end

    test "halts conn and returns 401 when JWK fetch fails", %{
      valid_token: valid_token
    } do
      # Arrange: Create a connection with a valid Authorization header
      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{valid_token}")

      KeycloakClientMock
      |> expect(:fetch_jwks, fn -> {:error, :unauthenticated} end)

      # Act: Call the Authenticate Plug
      returned_conn = Authenticate.call(conn, [])

      # Assert: The connection is halted and a 401 response is sent
      assert %{halted: true} = Plug.Conn.halt(returned_conn)
      assert returned_conn.state == :sent
      assert returned_conn.status == 401
    end

    test "halts conn and returns 401 when token verification fails", %{
      invalid_token: invalid_token
    } do
      # Arrange: Create a connection with an invalid token
      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{invalid_token}")

      KeycloakClientMock
      |> expect(:fetch_jwks, fn -> {:error, :unauthenticated} end)

      # Act: Call the Authenticate Plug
      returned_conn = Authenticate.call(conn, [])

      # Assert: The connection is halted and a 401 response is sent
      assert %{halted: true} = Plug.Conn.halt(returned_conn)
      assert returned_conn.state == :sent
      assert returned_conn.status == 401
    end
  end
end
